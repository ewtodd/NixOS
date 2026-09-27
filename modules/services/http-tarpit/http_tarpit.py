"""HTTP tarpits: accept connections and drip endless chunked responses.

Two listeners share the implementation and metrics. Port 9004 is the WAN
catch-all behind Anubis on llm.ethanwtodd.com; port 9005 is the
admin.ethanwtodd.com honeypot, which has no legitimate users at all. Counters
carry a `source` label so the bot-defense dashboard can split the two.
"""

import asyncio
import os
import random

from prometheus_client import Counter, Gauge, start_http_server

LISTEN_HOST = "127.0.0.1"
LISTEN_PORT = int(os.environ.get("TARPIT_PORT", "9004"))
HONEYPOT_PORT = int(os.environ.get("TARPIT_HONEYPOT_PORT", "9005"))
METRICS_PORT = int(os.environ.get("TARPIT_METRICS_PORT", "2113"))
DRIP_MIN_SECONDS = float(os.environ.get("TARPIT_DRIP_MIN_SECONDS", "1"))
DRIP_MAX_SECONDS = float(os.environ.get("TARPIT_DRIP_MAX_SECONDS", "5"))
MAX_CONNECTIONS = int(os.environ.get("TARPIT_MAX_CONNECTIONS", "2048"))

CRLF = b"\r\n"

CONNECTIONS = Counter(
    "http_tarpit_connections_total", "Connections accepted by the tarpit", ["source"]
)
REJECTED = Counter(
    "http_tarpit_rejected_total", "Connections closed at the concurrency cap", ["source"]
)
ACTIVE = Gauge(
    "http_tarpit_active_connections", "Connections currently held open", ["source"]
)
BYTES = Counter(
    "http_tarpit_bytes_sent_total", "Body bytes dripped to trapped clients", ["source"]
)
WASTED = Counter(
    "http_tarpit_wasted_seconds_total", "Client seconds held by the tarpit", ["source"]
)

HEADERS = (
    CRLF.join(
        [
            b"HTTP/1.1 200 OK",
            b"Content-Type: text/html; charset=utf-8",
            b"Cache-Control: no-store",
            b"Transfer-Encoding: chunked",
            b"Connection: keep-alive",
        ]
    )
    + CRLF
    + CRLF
)

active_connections = 0


def chunk(payload):
    return format(len(payload), "x").encode() + CRLF + payload + CRLF


async def trap(reader, writer, source):
    global active_connections
    if active_connections >= MAX_CONNECTIONS:
        REJECTED.labels(source).inc()
        writer.close()
        return
    active_connections += 1
    CONNECTIONS.labels(source).inc()
    ACTIVE.labels(source).inc()
    try:
        writer.write(HEADERS)
        writer.write(chunk(b"<html><head><title>Loading</title></head><body>"))
        await writer.drain()
        while True:
            delay = random.uniform(DRIP_MIN_SECONDS, DRIP_MAX_SECONDS)
            await asyncio.sleep(delay)
            WASTED.labels(source).inc(delay)
            line = "<p>{:08x} still loading</p>".format(random.randrange(1 << 32)).encode()
            writer.write(chunk(line))
            await writer.drain()
            BYTES.labels(source).inc(len(line))
    except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
        pass
    finally:
        active_connections -= 1
        ACTIVE.labels(source).dec()
        writer.close()
        try:
            await writer.wait_closed()
        except (ConnectionResetError, BrokenPipeError):
            pass


async def main():
    start_http_server(METRICS_PORT, addr=LISTEN_HOST)
    wan = await asyncio.start_server(
        lambda reader, writer: trap(reader, writer, "llm"),
        LISTEN_HOST,
        LISTEN_PORT,
        backlog=1024,
    )
    honeypot = await asyncio.start_server(
        lambda reader, writer: trap(reader, writer, "admin"),
        LISTEN_HOST,
        HONEYPOT_PORT,
        backlog=1024,
    )
    async with wan, honeypot:
        await asyncio.gather(wan.serve_forever(), honeypot.serve_forever())


asyncio.run(main())

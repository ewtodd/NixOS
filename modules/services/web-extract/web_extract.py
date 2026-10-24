"""Page extraction for the house's agents.

POST /extract {"url": "..."} answers {"url", "final_url", "title", "content",
"content_type", "error"}; GET /health answers "ok". HTML pages are rendered
in headless Chromium by Crawl4AI and returned as markdown; PDFs and text
types are read from the fetched bytes. A failed extraction still answers
200, with "error" set.

The pre-fetch refuses non-public addresses on every redirect hop. The
browser's own requests are kept off the LAN by the unit's IP filter.
"""

import argparse
import asyncio
import io
import ipaddress
import logging
import re
import socket
from urllib.parse import urljoin, urlsplit

import httpx
from aiohttp import web
from charset_normalizer import from_bytes
from crawl4ai import AsyncWebCrawler, BrowserConfig, CacheMode, CrawlerRunConfig
from crawl4ai.content_filter_strategy import PruningContentFilter
from crawl4ai.markdown_generation_strategy import DefaultMarkdownGenerator
from pypdf import PdfReader

log = logging.getLogger("web-extract")

MAX_BYTES = 25 * 1024 * 1024
MAX_REDIRECTS = 5
REQUEST_TIMEOUT = 90
HTML_TYPES = ("text/html", "application/xhtml+xml")
TEXT_TYPES = ("text/", "application/json", "application/xml", "application/rss+xml", "application/atom+xml")
USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/140.0 Safari/537.36"
)
IMAGE = re.compile(r"!\[([^\]]*)\]\([^)]*\)")

# remove_overlay_elements stays off: it strips Wikipedia's whole body as an
# overlay. header and form are not excluded for the same reason.
# Waiting for DOMContentLoaded hung for the whole timeout on some pages here
# (likely a blocking script whose host the unit's IP filter drops silently);
# a committed navigation plus a 2 s render gives the same text everywhere tested.
RUN_CONFIG = CrawlerRunConfig(
    cache_mode=CacheMode.BYPASS,
    excluded_tags=["nav", "footer", "aside", "noscript"],
    markdown_generator=DefaultMarkdownGenerator(
        content_filter=PruningContentFilter(),
        options={"ignore_links": True, "ignore_images": False, "body_width": 0},
    ),
    wait_until="commit",
    page_timeout=20000,
    delay_before_return_html=2.0,
    verbose=False,
)


class Refused(Exception):
    pass


class RenderFailed(Exception):
    pass


async def check_public(url: str) -> None:
    """Raises Refused unless url is http(s) and every address its host resolves to is global."""
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https") or not parts.hostname:
        raise Refused(f"unsupported URL: {url}")
    try:
        infos = await asyncio.get_running_loop().getaddrinfo(parts.hostname, parts.port or 443, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise Refused(f"cannot resolve {parts.hostname}: {exc}") from exc
    for info in infos:
        if not ipaddress.ip_address(info[4][0]).is_global:
            raise Refused(f"{parts.hostname} resolves to a non-public address")


async def prefetch(client: httpx.AsyncClient, url: str) -> tuple[str, str, bytes]:
    """Follows up to MAX_REDIRECTS redirects, checking each hop; returns (final_url, content_type, body)."""
    for _ in range(MAX_REDIRECTS + 1):
        await check_public(url)
        async with client.stream("GET", url) as resp:
            if resp.is_redirect and "location" in resp.headers:
                url = urljoin(url, resp.headers["location"])
                continue
            resp.raise_for_status()
            body = bytearray()
            async for chunk in resp.aiter_bytes():
                body += chunk
                if len(body) > MAX_BYTES:
                    raise Refused(f"larger than {MAX_BYTES // (1024 * 1024)} MB")
            ctype = resp.headers.get("content-type", "").split(";")[0].strip().lower()
            return str(resp.url), ctype, bytes(body)
    raise Refused(f"more than {MAX_REDIRECTS} redirects")


def pdf_text(body: bytes) -> tuple[str, str]:
    reader = PdfReader(io.BytesIO(body))
    title = (reader.metadata.title if reader.metadata else None) or ""
    pages = [(page.extract_text() or "").strip() for page in reader.pages]
    return title, "\n\n".join(p for p in pages if p)


def decode_text(body: bytes) -> str:
    best = from_bytes(body).best()
    return str(best) if best is not None else body.decode("utf-8", errors="replace")


def tidy_markdown(md: str) -> str:
    """Images become [IMAGE: alt] (decorative, alt-less ones are dropped); blank runs collapse."""
    md = IMAGE.sub(lambda m: f"[IMAGE: {m.group(1).strip()}]" if m.group(1).strip() else "", md)
    return re.sub(r"\n{3,}", "\n\n", md).strip()


class Extractor:
    def __init__(self, concurrency: int):
        self.crawler: AsyncWebCrawler | None = None
        self.browser_slots = asyncio.Semaphore(concurrency)
        self.client = httpx.AsyncClient(
            follow_redirects=False,
            timeout=httpx.Timeout(30.0, connect=10.0),
            headers={"User-Agent": USER_AGENT, "Accept": "*/*"},
        )

    async def start(self, _app=None):
        self.crawler = AsyncWebCrawler(config=BrowserConfig(headless=True, verbose=False))
        await self.crawler.start()

    async def stop(self, _app=None):
        if self.crawler is not None:
            await self.crawler.close()
        await self.client.aclose()

    async def render(self, url: str) -> tuple[str, str]:
        async with self.browser_slots:
            result = await self.crawler.arun(url, config=RUN_CONFIG)
        if not result.success:
            raise RenderFailed(result.error_message or "the browser could not load the page")
        raw = result.markdown.raw_markdown or ""
        fit = result.markdown.fit_markdown or ""
        # The pruning filter occasionally drops most of a page; keep the unfiltered text then.
        content = fit if len(fit) >= 0.3 * len(raw) else raw
        return (result.metadata or {}).get("title") or "", tidy_markdown(content)

    async def extract(self, url: str) -> dict:
        out = {"url": url, "final_url": url, "title": "", "content": "", "content_type": "", "error": None}
        status = None
        try:
            try:
                final_url, ctype, body = await prefetch(self.client, url)
            except httpx.HTTPStatusError as exc:
                # Bot walls refuse the plain client (403, 429, ...) and let a browser through.
                status = exc.response.status_code
                ctype, body = "text/html", b""
                final_url = url
            out.update(final_url=final_url, content_type=ctype)
            if ctype == "application/pdf" or body.startswith(b"%PDF-"):
                out["title"], out["content"] = pdf_text(body)
            elif ctype in HTML_TYPES or (not ctype and b"<html" in body[:2048].lower()):
                try:
                    out["title"], out["content"] = await self.render(final_url)
                except RenderFailed as exc:
                    out["error"] = f"HTTP {status}" if status else f"could not render the page: {exc}"
            elif ctype.startswith(TEXT_TYPES):
                out["content"] = decode_text(body)
            else:
                out["error"] = f"unsupported content type {ctype or 'unknown'}"
            if not out["error"] and not out["content"].strip():
                out["error"] = "no readable content"
        except Refused as exc:
            out["error"] = f"Blocked: {exc}"
        except httpx.HTTPError as exc:
            out["error"] = f"fetch failed: {exc.__class__.__name__}"
        except Exception as exc:  # noqa: BLE001
            log.exception("extracting %s", url)
            out["error"] = f"extraction failed: {exc.__class__.__name__}"
        return out


async def handle_extract(request: web.Request) -> web.Response:
    try:
        payload = await request.json()
        url = str(payload["url"]).strip()
    except Exception:  # noqa: BLE001
        return web.json_response({"error": 'expected JSON {"url": "..."}'}, status=400)
    extractor: Extractor = request.app["extractor"]
    try:
        result = await asyncio.wait_for(extractor.extract(url), REQUEST_TIMEOUT)
    except asyncio.TimeoutError:
        result = {"url": url, "final_url": url, "title": "", "content": "", "content_type": "",
                  "error": f"timed out after {REQUEST_TIMEOUT} s"}
    log.info("%s -> %s (%d chars)", url, result["error"] or "ok", len(result["content"]))
    return web.json_response(result)


async def handle_health(_request: web.Request) -> web.Response:
    return web.Response(text="ok")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8890)
    parser.add_argument("--concurrency", type=int, default=3)
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    extractor = Extractor(args.concurrency)
    app = web.Application()
    app["extractor"] = extractor
    app.on_startup.append(extractor.start)
    app.on_cleanup.append(extractor.stop)
    app.add_routes([web.post("/extract", handle_extract), web.get("/health", handle_health)])
    web.run_app(app, host=args.host, port=args.port, print=None)


if __name__ == "__main__":
    main()

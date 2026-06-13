"""SearXNG web-search MCP server (stdio).

Registered in the LiteLLM proxy via ``mcp_servers.searxng`` and spawned as a
stdio subprocess of the proxy inside the litellm container on son-of-anton. The
container shares the host network namespace, so ``SEARXNG_URL`` reaches the
host-local SearXNG instance (127.0.0.1:8888).

Exposes a single ``web_search`` tool over SearXNG's JSON API. The aggregated
gateway (LiteLLM ``/mcp``) presents it to both qwen-code and LibreChat alongside
the ``fetch`` server, so the models gain internet search + URL fetch.

Pure stdlib + httpx + the MCP SDK's FastMCP helper; no build-time network.
"""

import os

import httpx
from mcp.server.fastmcp import FastMCP

SEARXNG_URL = os.environ.get("SEARXNG_URL", "http://127.0.0.1:8888").rstrip("/")

mcp = FastMCP("searxng")


@mcp.tool()
def web_search(query: str, count: int = 5) -> str:
    """Search the web via the local SearXNG instance.

    Args:
        query: The search query.
        count: Maximum number of results to return (default 5).

    Returns a ranked list of results as "title / url / snippet" blocks.
    """
    resp = httpx.get(
        f"{SEARXNG_URL}/search",
        params={"q": query, "format": "json"},
        timeout=15.0,
    )
    resp.raise_for_status()
    results = resp.json().get("results", [])[: max(1, count)]
    if not results:
        return "No results."
    blocks = []
    for i, r in enumerate(results, 1):
        title = (r.get("title") or "").strip()
        url = (r.get("url") or "").strip()
        content = (r.get("content") or "").strip()
        blocks.append(f"{i}. {title}\n   {url}\n   {content}")
    return "\n\n".join(blocks)


if __name__ == "__main__":
    mcp.run()

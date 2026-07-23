"""Image viewer MCP server (stdio).

Spawns as a stdio subprocess and provides a ``view_image`` tool that accepts
either a local file path or an HTTP/HTTPS URL, reads the image, and sends it
to a vision-capable model (gemma-4-12b-router) via the LiteLLM API for
analysis.

Default ``LITELLM_URL`` points to the public gateway; override to
``http://127.0.0.1:4000`` when running inside the litellm container for a
loopback call.
"""

import base64
import mimetypes
import os
import pathlib
import traceback

import httpx
from mcp.server.fastmcp import FastMCP

LITELLM_URL = os.environ.get("LITELLM_URL", "https://llm.ethanwtodd.com/v1")
LITELLM_KEY = os.environ.get("LITELLM_MASTER_KEY", "")
VISION_MODEL = os.environ.get("VISION_MODEL", "gemma-4-12b-router")

mcp = FastMCP("image-viewer")


def _analyze(content_block: dict, prompt: str) -> str:
    body = {
        "model": VISION_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    content_block,
                ],
            }
        ],
        "temperature": 0.7,
        "max_tokens": 2048,
    }
    try:
        resp = httpx.post(
            f"{LITELLM_URL}/chat/completions",
            headers={"Authorization": f"Bearer {LITELLM_KEY}"},
            json=body,
            timeout=120.0,
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]
    except httpx.HTTPStatusError as e:
        detail = e.response.text[:500] if e.response.text else str(e)
        raise RuntimeError(
            f"Vision model API error ({e.response.status_code}): {detail}"
        )
    except httpx.RequestError as e:
        raise RuntimeError(f"Vision model API request failed: {e}")


@mcp.tool()
def view_image(path: str, prompt: str = "Describe this image in detail.") -> str:
    """Analyze an image via a vision-capable model (gemma-4-12b-router).

    Accepts a local file path or an http/https URL. The image is read, base64-
    encoded, and sent to the vision model for analysis.

    Args:
        path: Local file path or http/https URL of the image.
        prompt: What to ask about the image.
    """
    try:
        if path.startswith(("http://", "https://")):
            img = httpx.get(path, timeout=30.0)
            img.raise_for_status()
            b64 = base64.b64encode(img.content).decode("utf-8")
            ctype = img.headers.get("content-type", "image/png")
        else:
            data = pathlib.Path(path).read_bytes()
            b64 = base64.b64encode(data).decode("utf-8")
            ctype, _ = mimetypes.guess_type(path)
            ctype = ctype or "image/png"
    except PermissionError:
        import getpass
        raise RuntimeError(
            f"Permission denied reading '{path}'. "
            f"Process runs as '{getpass.getuser()}' (uid={os.getuid()}), "
            f"file owner is '{pathlib.Path(path).owner()}'"
        )
    except FileNotFoundError:
        raise RuntimeError(f"File not found: '{path}'")
    except OSError as e:
        raise RuntimeError(f"Error reading '{path}': {e}")

    return _analyze(
        {"type": "image_url", "image_url": {"url": f"data:{ctype};base64,{b64}"}},
        prompt,
    )


if __name__ == "__main__":
    mcp.run()

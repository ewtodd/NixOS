"""LiteLLM content-based router for the ``auto`` model.

Registered via ``litellm_settings.callbacks = ["classifier.router"]``. Runs inside
the LiteLLM proxy container on son-of-anton. Rewrites ``data["model"]`` when the
client asks for ``auto``; explicit model names pass through untouched.

Tiers (the classifier picks one; session-sticky so a tool-loop never bounces).
All three live on son-of-anton, so routing is purely about speed-vs-brains:
  smart-coder - coding (any complexity)  (80B-A3B coder, ~42 t/s)
  ultra-fast  - general + simple         (30B-A3B, ~100 t/s)
  big-moe     - general + complex        (122B-A10B orchestrator)

Routing policy: CLASSIFY on the *stable* conversation prefix (system prompt +
first user message): coding-vs-general, and simple-vs-complex for the general
side. The verdict is cached on the prefix, so an agentic tool-loop (many
requests sharing that prefix) stays pinned to one backend -> consistent
behaviour, KV reuse, and no mid-session model swap on son-of-anton.

All tiers run with >=64k context on son-of-anton, so there is no per-request
token-overflow escalation (the old 16GB fast-coder hard rule is gone along
with the e-desktop backend, which now only serves nvim FIM completion).

``gpt-oss-120b`` is intentionally NOT reachable via ``auto`` -- it is
name-selectable only.

The classifier is pure-Python string heuristics (sub-millisecond, no model); it
can be swapped for embedding similarity later without changing this hook.
"""

import hashlib
from collections import OrderedDict

from litellm.integrations.custom_logger import CustomLogger

SMART_CODER = "smart-coder"
ULTRA_FAST = "ultra-fast"
BIG_MOE = "big-moe"
ROUTED_NAME = "auto"

# Complexity signals -> the "complex" half of the general pair.
COMPLEX_KEYWORDS = (
    "architect", "design", "refactor", "rewrite", "migrate", "debug",
    "root cause", "trace through", "why does", "why is", "explain how",
    "step by step", "multi-step", "across the codebase", "whole repo",
    "entire codebase", "trade-off", "tradeoff", "high-level plan",
)
# Coding signals -> smart-coder. opencode's system prompt is code-centric,
# so its requests land here; a general chat client falls to the general tiers.
CODING_KEYWORDS = (
    "code", "coding", "function", "class ", "method", "compile", "bug",
    "stack trace", "traceback", "refactor", "implement", "debug", "repository",
    "repo", "git ", "commit", "module", "import", "unit test", "syntax",
    "software engineer", "programming", "endpoint", "schema",
)
COMPLEX_PREFIX_CHARS = 4000


def _stable_prefix(messages):
    """(system prompt + first user message) - constant across a tool-loop."""
    system = " ".join(
        m.get("content", "")
        for m in messages
        if m.get("role") == "system" and isinstance(m.get("content"), str)
    )
    first_user = ""
    for m in messages:
        if m.get("role") == "user" and isinstance(m.get("content"), str):
            first_user = m["content"]
            break
    return (system + "\n" + first_user).strip()


def _classify(prefix: str) -> str:
    low = prefix.lower()
    coding = ("```" in prefix) or any(k in low for k in CODING_KEYWORDS)
    if coding:
        return SMART_CODER
    complex_ = len(prefix) >= COMPLEX_PREFIX_CHARS or any(
        k in low for k in COMPLEX_KEYWORDS
    )
    return BIG_MOE if complex_ else ULTRA_FAST


class _Router(CustomLogger):
    def __init__(self, cache_size: int = 2048):
        super().__init__()
        self._verdicts: "OrderedDict[str, str]" = OrderedDict()
        self._cache_size = cache_size

    def _sticky(self, prefix: str) -> str:
        key = hashlib.sha256(prefix.encode("utf-8")).hexdigest()
        if key in self._verdicts:
            self._verdicts.move_to_end(key)
            return self._verdicts[key]
        verdict = _classify(prefix)
        self._verdicts[key] = verdict
        if len(self._verdicts) > self._cache_size:
            self._verdicts.popitem(last=False)
        return verdict

    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        if data.get("model") != ROUTED_NAME:
            return data
        messages = data.get("messages") or []
        data["model"] = self._sticky(_stable_prefix(messages))
        return data


# Instance referenced by litellm_settings.callbacks = ["classifier.router"].
router = _Router()

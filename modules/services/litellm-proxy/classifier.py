"""LiteLLM content-based router for the ``auto`` model.

Registered via ``litellm_settings.callbacks = ["classifier.router"]``. Runs inside
the LiteLLM proxy container on mu. Rewrites ``data["model"]`` when the client asks
for ``auto``; explicit model names pass through untouched.

Tiers (the classifier picks one; session-sticky so a tool-loop never bounces):
  fast-coder  - coding  + simple    (e-desktop 14B, isolated, instant)
  smart-coder - coding  + complex   (son-of-anton 80B-A3B)
  ultra-fast  - general + simple    (son-of-anton 30B-A3B)
  big-moe     - general + complex   (son-of-anton orchestrator)

Routing policy (priority order):
  1. CLASSIFY on the *stable* conversation prefix (system prompt + first user
     message): coding-vs-general x simple-vs-complex -> one of the four tiers.
     The verdict is cached on the prefix, so an agentic tool-loop (many requests
     sharing that prefix) stays pinned to one backend -> consistent behaviour,
     KV reuse, and no mid-session model swap on son-of-anton.
  2. HARD RULE (per request): only ``fast-coder`` runs on the 16GB box with a
     32k context; if a request's estimated prompt tokens exceed what it can hold
     with KV headroom, escalate that one request to ``smart-coder`` (same coding
     role, far larger context). The son-of-anton tiers have ample context, so
     they need no overflow guard.

``qwen3.5-122b`` and ``minimax`` are intentionally NOT reachable via ``auto`` --
they are name-selectable only.

The classifier is pure-Python string heuristics (sub-millisecond, no model); it
can be swapped for embedding similarity later without changing this hook.
"""

import hashlib
from collections import OrderedDict

import litellm
from litellm.integrations.custom_logger import CustomLogger

FAST_CODER = "fast-coder"
SMART_CODER = "smart-coder"
ULTRA_FAST = "ultra-fast"
BIG_MOE = "big-moe"
ROUTED_NAME = "auto"

# -- Hard-rule threshold ------------------------------------------------------
# Only fast-coder is constrained: Qwen2.5-Coder-14B (Q5_K_M GGUF) on llama.cpp,
# 16GB 5080, served with --ctx-size 32768. Escalate at 75% of that, leaving
# headroom for generation: 32768 * 0.75 = 24576 -> 24000 (round down). The
# son-of-anton tiers (--ctx-size 65536) have no such limit at these sizes.
HARD_TOKEN_THRESHOLD = 24000

# Complexity signals -> the "complex" half of each pair.
COMPLEX_KEYWORDS = (
    "architect", "design", "refactor", "rewrite", "migrate", "debug",
    "root cause", "trace through", "why does", "why is", "explain how",
    "step by step", "multi-step", "across the codebase", "whole repo",
    "entire codebase", "trade-off", "tradeoff", "high-level plan",
)
# Coding signals -> the "coding" half. opencode's system prompt is code-centric,
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
    complex_ = len(prefix) >= COMPLEX_PREFIX_CHARS or any(
        k in low for k in COMPLEX_KEYWORDS
    )
    if coding:
        return SMART_CODER if complex_ else FAST_CODER
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

        target = self._sticky(_stable_prefix(messages))

        # HARD RULE: fast-coder (16GB, 32k ctx) can't hold huge prompts -> bump
        # this request to smart-coder (same role, 64k ctx on son-of-anton).
        if target == FAST_CODER:
            try:
                est = litellm.token_counter(model=FAST_CODER, messages=messages)
            except Exception:
                est = sum(len(m.get("content") or "") for m in messages) // 4
            if est > HARD_TOKEN_THRESHOLD:
                target = SMART_CODER

        data["model"] = target
        return data


# Instance referenced by litellm_settings.callbacks = ["classifier.router"].
router = _Router()

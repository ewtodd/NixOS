"""LiteLLM pre-call hook: classifier-based "auto" model routing.

When a request targets the model name "auto", rewrite it to a concrete model:

  * if the request carries an image attachment -> a vision model, decided
    deterministically (the text-only classifier can't see images);
  * otherwise -> ask the always-resident Qwen3-0.6B to label the request and
    map that label to a model.

Registered via litellm_settings.callbacks (see the litellm-proxy module). The
classifier call is made straight to the local llama-swap backend rather than
back through the proxy, so it can never recurse into "auto".

This is the building block for pointing other OpenAI-compatible agents (e.g.
Nous Hermes Agent on son-of-anton) at a single "auto" model and letting the
gateway pick the right backend.
"""

import json

import litellm
from litellm.integrations.custom_logger import CustomLogger

AUTO_MODEL = "auto"

# Classifier backend: hit llama-swap directly (NOT the proxy) to avoid recursing
# through "auto". qwen3-0.6b is alwaysResident with reasoning forced off
# server-side, so this is a cheap, always-warm call.
CLASSIFIER_API_BASE = "http://127.0.0.1:8080/v1"
CLASSIFIER_MODEL = "openai/qwen3-0.6b"

# Targets must match LiteLLM model_list `model_name`s exactly.
DEFAULT_MODEL = "Qwen3.6-35B-A3B (default)"
VISION_MODEL = "Mistral-Small-4-119B (vision)"
LABEL_TO_MODEL = {
    "code": "Qwen3-Coder-Next (smart-coder)",
    "reasoning": "Qwen3.5-122B-A10B (big-moe)",
    "simple": "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)",
    "general": DEFAULT_MODEL,
}

SYSTEM_PROMPT = (
    "You are a request router. Read the user's message and classify it into "
    "exactly one of these categories:\n"
    "- code: writing, debugging, refactoring, or explaining code\n"
    "- reasoning: hard math, logic, or multi-step analysis/planning\n"
    "- simple: quick facts, greetings, or short trivial tasks\n"
    "- general: anything that does not clearly fit the above\n"
    'Respond ONLY with a JSON object: {"label": "<category>"}.'
)

# Constrain the 0.6B to a valid label (llama.cpp honors json_schema). The hook
# also tolerates non-JSON output below, so this is belt-and-suspenders.
RESPONSE_FORMAT = {
    "type": "json_schema",
    "json_schema": {
        "name": "route",
        "strict": True,
        "schema": {
            "type": "object",
            "properties": {"label": {"type": "string", "enum": list(LABEL_TO_MODEL)}},
            "required": ["label"],
            "additionalProperties": False,
        },
    },
}


def _has_image(messages):
    for m in messages:
        content = m.get("content")
        if isinstance(content, list):
            for part in content:
                if isinstance(part, dict) and part.get("type") in (
                    "image_url",
                    "image",
                    "input_image",
                ):
                    return True
    return False


def _last_user_text(messages):
    for m in reversed(messages):
        if m.get("role") != "user":
            continue
        content = m.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts = [
                p.get("text", "")
                for p in content
                if isinstance(p, dict) and p.get("type") == "text"
            ]
            if parts:
                return "\n".join(parts)
    return ""


async def _classify(text):
    text = (text or "").strip()
    if not text:
        return DEFAULT_MODEL
    raw = ""
    try:
        resp = await litellm.acompletion(
            model=CLASSIFIER_MODEL,
            api_base=CLASSIFIER_API_BASE,
            api_key="none",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": text[:4000]},
            ],
            temperature=0.0,
            max_tokens=16,
            response_format=RESPONSE_FORMAT,
        )
        raw = resp["choices"][0]["message"]["content"] or ""
        label = json.loads(raw).get("label", "").strip().lower()
    except Exception:
        # Backend hiccup or non-JSON output: try a loose substring match, then
        # fall back to the default model.
        label = next((l for l in LABEL_TO_MODEL if l in raw.lower()), "")
    return LABEL_TO_MODEL.get(label, DEFAULT_MODEL)


class AutoRouter(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        if data.get("model") != AUTO_MODEL:
            return data
        messages = data.get("messages", []) or []
        if _has_image(messages):
            data["model"] = VISION_MODEL
        else:
            data["model"] = await _classify(_last_user_text(messages))
        return data


# Referenced as "auto_router.auto_router" in litellm_settings.callbacks.
auto_router = AutoRouter()

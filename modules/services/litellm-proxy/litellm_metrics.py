"""LiteLLM Prometheus metrics exporter (in-process callback).

Registered via ``litellm_settings.callbacks = ["litellm_metrics.metrics"]``.
Runs INSIDE the LiteLLM proxy process on son-of-anton.

Why a callback and not a sidecar: LiteLLM's request telemetry lives in the
proxy's own address space. A separate process can observe nothing -- it would
only ever serve zeros. So the success/failure hooks and the HTTP ``/metrics``
server share this module's in-memory counters under one lock, exactly like the
classifier shares the proxy process.

The HTTP server binds 0.0.0.0:9192 (the litellm container shares the host net
namespace; the host firewall opens 9192). nu's Prometheus scrapes
10.0.0.5:9192 as job "litellm".

Metrics:
  litellm_requests_total{model,status}            counter (success/error)
  litellm_tokens_total{model,type}                counter (prompt/completion)
  litellm_request_duration_seconds{model}         histogram
  litellm_active_requests{model}                  gauge (in-flight)
  litellm_active_sessions                          gauge (clients seen <5min)
  litellm_up                                       gauge (1 = exporter alive)
"""

import threading
import time
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, HTTPServer

from litellm.integrations.custom_logger import CustomLogger

PORT = 9192
SESSION_TIMEOUT = 300  # a client counts as an active session for this long
DURATION_BUCKETS = [0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 30.0, 60.0]

_lock = threading.Lock()
_requests = defaultdict(int)         # (model, status)  -> count
_tokens = defaultdict(int)           # (model, type)    -> count
_active_requests = defaultdict(int)  # model            -> in-flight
_dur_buckets = defaultdict(int)      # (model, le)      -> cumulative count
_dur_sum = defaultdict(float)        # model            -> sum of durations
_dur_count = defaultdict(int)        # model            -> observation count
_sessions = {}                       # client           -> last-seen epoch

_server_started = False


def _skip(model):
    """MCP gateway calls (e.g. tool listing) flow through the logging hooks as
    pseudo-models like "MCP: list_tools" -- not real LLM traffic, so drop them
    instead of polluting the by-model breakdown with 0-token entries."""
    return str(model).startswith("MCP")


def _label(value):
    """Escape a Prometheus label value."""
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\n", " ")
    )


def _get(obj, attr, default=0):
    """Read ``attr`` whether ``obj`` is a dict or an object (e.g. usage)."""
    if isinstance(obj, dict):
        return obj.get(attr, default)
    return getattr(obj, attr, default)


def _render():
    now = time.time()
    out = []
    with _lock:
        for client in [c for c, ts in _sessions.items() if now - ts > SESSION_TIMEOUT]:
            del _sessions[client]

        out.append("# HELP litellm_up LiteLLM metrics exporter alive (1=up)")
        out.append("# TYPE litellm_up gauge")
        out.append("litellm_up 1")

        out.append("# HELP litellm_requests_total Requests by model and status")
        out.append("# TYPE litellm_requests_total counter")
        for (model, status), n in sorted(_requests.items()):
            out.append(
                f'litellm_requests_total{{model="{_label(model)}",status="{_label(status)}"}} {n}'
            )

        out.append("# HELP litellm_tokens_total Tokens by model and type")
        out.append("# TYPE litellm_tokens_total counter")
        for (model, type_), n in sorted(_tokens.items()):
            out.append(
                f'litellm_tokens_total{{model="{_label(model)}",type="{type_}"}} {n}'
            )

        out.append("# HELP litellm_request_duration_seconds Request duration")
        out.append("# TYPE litellm_request_duration_seconds histogram")
        for model in sorted(_dur_count):
            m = _label(model)
            for b in DURATION_BUCKETS:
                out.append(
                    f'litellm_request_duration_seconds_bucket{{model="{m}",le="{b}"}} '
                    f"{_dur_buckets[(model, b)]}"
                )
            out.append(
                f'litellm_request_duration_seconds_bucket{{model="{m}",le="+Inf"}} '
                f"{_dur_count[model]}"
            )
            out.append(f'litellm_request_duration_seconds_sum{{model="{m}"}} {_dur_sum[model]}')
            out.append(f'litellm_request_duration_seconds_count{{model="{m}"}} {_dur_count[model]}')

        out.append("# HELP litellm_active_requests In-flight requests by model")
        out.append("# TYPE litellm_active_requests gauge")
        for model, n in sorted(_active_requests.items()):
            out.append(f'litellm_active_requests{{model="{_label(model)}"}} {max(0, n)}')

        # Single always-present series so the stat panel shows 0, not "No data".
        out.append("# HELP litellm_active_sessions Distinct clients seen in the last 5 minutes")
        out.append("# TYPE litellm_active_sessions gauge")
        out.append(f"litellm_active_sessions {len(_sessions)}")

    return "\n".join(out) + "\n"


class _Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # don't spam the journal with one line per scrape

    def do_GET(self):
        if self.path != "/metrics":
            self.send_response(404)
            self.end_headers()
            return
        body = _render().encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def _start_server_once():
    global _server_started
    with _lock:
        if _server_started:
            return
        _server_started = True
    server = HTTPServer(("0.0.0.0", PORT), _Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()


class _Metrics(CustomLogger):
    """LiteLLM callback feeding the in-process Prometheus exporter."""

    def __init__(self):
        super().__init__()
        _start_server_once()

    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        # data["model"] is the model the client selected (no auto-routing).
        model = data.get("model") or "Misc."
        if _skip(model):
            return data
        client = (
            data.get("user")
            or getattr(user_api_key_dict, "end_user_id", None)
            or getattr(user_api_key_dict, "key_alias", None)
            or "default"
        )
        with _lock:
            _active_requests[model] += 1
            _sessions[client] = time.time()
        return data  # never mutate the request

    async def async_log_success_event(self, kwargs, response_obj, start_time, end_time):
        try:
            self._record(kwargs, response_obj, start_time, end_time, "success")
        except Exception:
            pass  # telemetry must never break a request

    async def async_log_failure_event(self, kwargs, response_obj, start_time, end_time):
        try:
            self._record(kwargs, response_obj, start_time, end_time, "error")
        except Exception:
            pass

    def _record(self, kwargs, response_obj, start_time, end_time, status):
        slo = kwargs.get("standard_logging_object") or {}
        # model_group is the public model_name; fall back to the deployment model.
        model = slo.get("model_group") or kwargs.get("model") or "Misc."
        if _skip(model):
            return

        prompt = slo.get("prompt_tokens")
        completion = slo.get("completion_tokens")
        if prompt is None or completion is None:
            usage = getattr(response_obj, "usage", None) or {}
            if prompt is None:
                prompt = _get(usage, "prompt_tokens", 0)
            if completion is None:
                completion = _get(usage, "completion_tokens", 0)

        duration = None
        try:
            duration = (end_time - start_time).total_seconds()
        except Exception:
            duration = None

        with _lock:
            _requests[(model, status)] += 1
            if status == "success":
                _tokens[(model, "prompt")] += int(prompt or 0)
                _tokens[(model, "completion")] += int(completion or 0)
            if duration is not None and duration >= 0:
                for b in DURATION_BUCKETS:
                    if duration <= b:
                        _dur_buckets[(model, b)] += 1
                _dur_sum[model] += duration
                _dur_count[model] += 1
            # request finished -> drop the in-flight count for this model.
            if model in _active_requests:
                _active_requests[model] = max(0, _active_requests[model] - 1)


# Instance referenced by litellm_settings.callbacks = ["litellm_metrics.metrics"].
metrics = _Metrics()

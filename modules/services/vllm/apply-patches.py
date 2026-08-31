#!/usr/bin/env python3
"""
Post-install patches for vLLM on gfx1201 (RDNA4 / Radeon AI PRO R9700).

The wheels from wheels.vllm.ai are built for CDNA data-center parts and ship
autotune/config choices that exceed RDNA4's 64 KiB LDS budget. Each entry below
is applied to the installed venv and verified; the provisioning unit refuses to
start vLLM if any required patch could not be applied.

Every patch is idempotent: `marker` is a string that only exists once the patch
is in place, so re-running is a no-op and an upstream bump that absorbs a patch
shows up as FAILED (anchor gone) rather than silently doing nothing.

Usage:
  apply-patches.py --site-packages DIR [--check]

  --check   report status and exit non-zero if a required patch is not applied,
            without modifying anything.
"""

import argparse
import py_compile
import sys
from pathlib import Path

MARK = "rdna4-lds-guard"
PROBE = "spec-draft-index-probe"
HANG = "tp-hang-stack-dumper"
SHAPE = "gdn-shape-recorder"
GDN = "rdna4-gdn-contig"

PATCHES = [
    {
        "id": "aiter-3d-attn-stages",
        "file": "aiter/ops/triton/attention/unified_attention.py",
        "required": True,
        "note": (
            "select_3d_config only special-cases gfx1250, so gfx1201 falls through to "
            "the CDNA-tuned attn_stages=2 (double-buffered), which needs 65792 B of LDS "
            "against RDNA4's 65536 B limit. select_2d_config already does this for "
            "arch.is_rdna a few lines above."
        ),
        "anchor": (
            "    reduce_num_warps = 2\n"
            "    attn_warps = 2\n"
            "    waves_per_eu = 2\n"
            "    num_segments = 0\n"
            "    attn_stages = 2\n"
            "    if IS_DEVICE_ARCH_GFX12:\n"
        ),
        "replacement": (
            "    reduce_num_warps = 2\n"
            "    attn_warps = 2\n"
            "    waves_per_eu = 2\n"
            "    num_segments = 0\n"
            "    attn_stages = 2\n"
            f"    if get_arch().is_rdna:  # {MARK}\n"
            "        # RDNA's 64KB LDS overflows with the double-buffered config below,\n"
            "        # which was tuned for CDNA/data-center chips.\n"
            "        attn_stages = 1\n"
            "    if IS_DEVICE_ARCH_GFX12:\n"
        ),
        "marker": f"if get_arch().is_rdna:  # {MARK}",
    },
    {
        "id": "fla-chunk-o-autotune",
        "file": "vllm/third_party/flash_linear_attention/ops/chunk_o.py",
        "required": True,
        "note": (
            "The autotune space offers configs needing 65792 B of shared memory. Usage "
            "scales with BK*BV and with num_stages (pipelining multiplies the staged "
            "buffers), so both must be bounded. check_shared_mem() only separates "
            "Hopper-class from everything else, and OutOfResources propagates rather "
            "than being pruned by the autotuner."
        ),
        "anchor": (
            "        for BK in BKV_LIST\n"
            "        for BV in BKV_LIST\n"
            "        for num_warps in NUM_WARPS\n"
            "        for num_stages in [2, 3, 4]"
        ),
        "replacement": (
            "        for BK in BKV_LIST\n"
            "        for BV in BKV_LIST\n"
            "        for num_warps in NUM_WARPS\n"
            f"        for num_stages in [2]  # {MARK}\n"
            f"        if BK * BV <= 2048  # {MARK}: RDNA4 has 65536B LDS; larger tiles need 65792B"
        ),
        "marker": f"for num_stages in [2]  # {MARK}",
    },
    {
        "id": "fla-chunk-size",
        "file": "vllm/third_party/flash_linear_attention/ops/utils.py",
        "required": True,
        "note": "BT=64 needs 65792 B of LDS, over RDNA4's 65536 B limit.",
        "anchor": "\nFLA_CHUNK_SIZE = 64",
        "replacement": f"\nFLA_CHUNK_SIZE = 32  # {MARK}: BT=64 needs 65792B LDS > 65536B limit",
        "marker": f"FLA_CHUNK_SIZE = 32  # {MARK}",
    },
    {
        "id": "spec-draft-index-probe",
        "file": "vllm/v1/worker/gpu_model_runner.py",
        "required": True,
        "note": (
            "DIAGNOSTIC. In the async-scheduling path, _prepare_input_ids gathers "
            "draft_token_ids.flatten()[prev_index * prev_num_spec_tokens + [0, draft_len)]. "
            "draft_len comes from the scheduler (padded to num_spec_tokens); the stride "
            "comes from the drafter's actual tensor width. Nothing reconciles them, and "
            "torch advanced indexing is NOT bounds-checked on device, so a mismatch reads "
            "unmapped VRAM -> gfxhub page fault, killing the worker with no Python "
            "traceback. This logs the operands when the index would go out of range, then "
            "clamps. Clamping is safe: draft tokens are verified by the target model, so a "
            "clamped draft is rejected, never emitted."
        ),
        "anchor": (
            "        assert isinstance(self._draft_token_ids, torch.Tensor)\n"
            "        draft_tokens_index_tensor = torch.tensor(\n"
        ),
        "replacement": (
            "        assert isinstance(self._draft_token_ids, torch.Tensor)\n"
            f"        # {PROBE}\n"
            "        _draft_numel = self._draft_token_ids.numel()\n"
            "        if prev_draft_token_indices:\n"
            "            _max_idx = max(prev_draft_token_indices)\n"
            "            if _max_idx >= _draft_numel:\n"
            "                logger.error(\n"
            '                    "%s OOB draft gather: max_idx=%d numel=%d shape=%s '
            'prev_num_spec_tokens=%d num_reqs=%d prev_indices=%s draft_lens=%s '
            'total_spec=%d total_sched=%d -- clamping",\n'
            f'                    "{PROBE}",\n'
            "                    _max_idx,\n"
            "                    _draft_numel,\n"
            "                    tuple(self._draft_token_ids.shape),\n"
            "                    self.prev_num_spec_tokens,\n"
            "                    num_reqs,\n"
            "                    prev_indices,\n"
            "                    [\n"
            "                        len(scheduled_spec_tokens.get(r, ()))\n"
            "                        for r in self.input_batch.req_ids[:num_reqs]\n"
            "                    ],\n"
            "                    total_num_spec_tokens,\n"
            "                    total_num_scheduled_tokens,\n"
            "                )\n"
            "                prev_draft_token_indices = [\n"
            "                    min(_i, _draft_numel - 1) for _i in prev_draft_token_indices\n"
            "                ]\n"
            "        draft_tokens_index_tensor = torch.tensor(\n"
        ),
        "marker": PROBE,
    },
    {
        "id": "tp-hang-stack-dumper",
        "file": "vllm/v1/executor/multiproc_executor.py",
        "required": True,
        "note": (
            "DIAGNOSTIC. TP=2 deadlocks on gfx1201 leave both workers spinning on-CPU "
            "(wchan=0) with no GPU fault and no Python traceback -- vllm#40980. The host "
            "runs ptrace_scope=1, so py-spy cannot attach without root. faulthandler's "
            "signal handler walks the interpreter state without taking the GIL, so it "
            "still dumps while the worker is wedged. On the next hang: "
            "`kill -USR1 $(pgrep -f VLLM::Worker)` and read every thread's stack out of "
            "journald -- that distinguishes a stuck RCCL collective from the "
            "shm_broadcast spin-wait."
        ),
        "anchor": (
            "        signal.signal(signal.SIGTERM, signal_handler)\n"
            "        signal.signal(signal.SIGINT, signal_handler)\n"
        ),
        "replacement": (
            "        signal.signal(signal.SIGTERM, signal_handler)\n"
            "        signal.signal(signal.SIGINT, signal_handler)\n"
            f"        # {HANG}: periodic stack snapshot (signal-free: SIGUSR1 delivery is\n"
            "        # unreliable while the dispatch thread busy-waits in the HIP runtime).\n"
            "        import faulthandler as _faulthandler\n"
            "        import threading as _threading\n"
            "        import time as _time\n"
            "        _hang_path = '/tmp/vllm-hang-%d.txt' % os.getpid()\n"
            "        _hang_env = 'AMD_SERIALIZE_KERNEL=%r HIP_VISIBLE=%r TORCH=%r'\n"
            "        def _hang_watchdog():\n"
            "            while True:\n"
            "                _time.sleep(15)\n"
            "                try:\n"
            "                    with open(_hang_path, 'w') as _f:\n"
            "                        _f.write('snapshot %s\\n' % _time.strftime('%H:%M:%S'))\n"
            "                        _f.write(_hang_env % (\n"
            "                            os.environ.get('AMD_SERIALIZE_KERNEL'),\n"
            "                            os.environ.get('HIP_VISIBLE_DEVICES'),\n"
            "                            __import__('torch').__version__,\n"
            "                        ) + chr(10))\n"
            "                        _m = __import__('sys').modules.get(\n"
            "                            'vllm.model_executor.layers.mamba.gdn'\n"
            "                            '.qwen_gdn_linear_attn')\n"
            "                        _f.write('gdn_last=%s' % getattr(\n"
            "                            _m, '_GDN_LAST', None) + chr(10))\n"
            "                        _faulthandler.dump_traceback(file=_f, all_threads=True)\n"
            "                except Exception:\n"
            "                    pass\n"
            "        _threading.Thread(\n"
            "            target=_hang_watchdog, daemon=True, name='hang-watchdog'\n"
            "        ).start()\n"
        ),
        "marker": HANG,
    },
    {
        "id": "gdn-shape-recorder",
        "file": "vllm/model_executor/layers/mamba/gdn/qwen_gdn_linear_attn.py",
        "required": True,
        "note": (
            "DIAGNOSTIC. rank 0 wedges inside rearrange_mixed_qkv on a strided copy "
            "(vllm#40980). Records the operands into a module global on every call -- no "
            "I/O in the hot path -- which the hang watchdog reads out at snapshot time. "
            "Gives the exact shape/dtype/stride needed to build a standalone reproducer."
        ),
        "anchor": (
            "        if mixed_qkv is None:\n"
            "            return None, None, None\n"
        ),
        "replacement": (
            "        if mixed_qkv is None:\n"
            "            return None, None, None\n"
            f"        # {SHAPE}: CONTROL EXPERIMENT. Sampling every 500th call, so the hot\n"
            "        # path carries an increment (~100ns) instead of a string format (~15us).\n"
            "        # The per-call version coincided with the TP=2 deadlock ceasing to\n"
            "        # reproduce for 170min. If it returns now, that version was masking a\n"
            "        # race by timing rather than fixing anything.\n"
            "        global _GDN_LAST, _GDN_N\n"
            "        try:\n"
            "            _GDN_N += 1\n"
            "        except NameError:\n"
            "            _GDN_N = 1\n"
            "        if _GDN_N % 500 == 0:\n"
            "            _GDN_LAST = (\n"
            "                'shape=%s stride=%s dtype=%s dev=%s contig=%s '\n"
            "                'key_dim=%s value_dim=%s tp=%s hk=%s hv=%s calls=%s'\n"
            "            ) % (\n"
            "                tuple(mixed_qkv.shape), tuple(mixed_qkv.stride()),\n"
            "                mixed_qkv.dtype, mixed_qkv.device,\n"
            "                mixed_qkv.is_contiguous(), self.key_dim, self.value_dim,\n"
            "                self.tp_size, self.head_k_dim, self.head_v_dim, _GDN_N,\n"
            "            )\n"
        ),
        "marker": SHAPE,
    },
]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--site-packages", required=True, type=Path)
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()

    sp: Path = args.site_packages
    if not sp.is_dir():
        print(f"!! site-packages not found: {sp}", file=sys.stderr)
        return 2

    failed, changed, touched = [], [], []

    for p in PATCHES:
        path = sp / p["file"]
        tag = f"{p['id']:<24}"

        if not path.exists():
            state, ok = "FILE MISSING", not p["required"]
        else:
            content = path.read_text()
            if p["marker"] in content:
                state, ok = "already applied", True
            elif p["anchor"] not in content:
                state, ok = "ANCHOR NOT FOUND (upstream changed?)", not p["required"]
            elif args.check:
                state, ok = "NOT APPLIED", False
            else:
                new = content.replace(p["anchor"], p["replacement"], 1)
                if p["marker"] not in new:
                    state, ok = "REPLACEMENT DID NOT TAKE", False
                else:
                    path.write_text(new)
                    touched.append(path)
                    changed.append(p["id"])
                    state, ok = "applied", True

        print(f"  [{'ok' if ok else '!!'}] {tag} {state}")
        if not ok:
            failed.append(p["id"])

    for path in touched:
        try:
            py_compile.compile(str(path), doraise=True)
        except py_compile.PyCompileError as e:
            print(f"  [!!] syntax error after patching {path}: {e}", file=sys.stderr)
            failed.append(str(path))

    if failed:
        print(f"\n!! {len(failed)} patch(es) not in place: {', '.join(failed)}", file=sys.stderr)
        return 1

    print(f"\nAll {len(PATCHES)} patches in place" + (f" ({len(changed)} newly applied)" if changed else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())

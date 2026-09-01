#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/lib/common.sh"

workspace="${BANANAPAD_WORKSPACE:-$BANANAPAD_ROOT/worktrees/bananapad-static-macos}"
events="$workspace/lib/N64ModernRuntime/ultramodern/src/events.cpp"
context="$BANANAPAD_ROOT/apple/core/bananapad_rt64_context.cpp"
gbi="$workspace/lib/rt64/src/gbi/rt64_gbi.cpp"
cmake="$workspace/CMakeLists.txt"
[[ -f "$events" ]] || die "runtime events source is missing: $events"
[[ -f "$context" ]] || die "BananaPad RT64 context source is missing: $context"
[[ -f "$gbi" ]] || die "RT64 GBI database source is missing: $gbi"
[[ -f "$cmake" ]] || die "BananaPad root CMake source is missing: $cmake"

python3 - "$events" "$context" "$gbi" "$cmake" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text()
branch = source.index("if (const auto* task_action = std::get_if<SpTaskAction>(&action))")
end = source.index("else if (const auto* screen_update_action", branch)
block = source[branch:end]

send = block.index("renderer_context->send_dl(&task_action->task);")
early_guard = block.index("#if !defined(BANANAPAD_NATIVE_SHELL)")
early_complete = block.index("sp_complete();", early_guard)
late_guard = block.index("#if defined(BANANAPAD_NATIVE_SHELL)", send)
late_complete = block.index("sp_complete();", late_guard)
dp_complete = block.index("dp_complete();")

assert early_guard < early_complete < send
assert send < late_guard < late_complete < dp_complete
assert "DK64 can replace its microcode data as soon as SP completes" in block

context = Path(sys.argv[2]).read_text()
load = context.index("app->interpreter->loadUCodeGBI")
guard = context.index("if (app->interpreter->hleGBI == nullptr)", load)
invalidate_text = context.index("UCode.textAddress = UINT32_MAX", guard)
invalidate_data = context.index("UCode.dataAddress = UINT32_MAX", guard)
guard_return = context.index("return;", guard)
process = context.index("app->processDisplayLists", load)
assert load < guard < invalidate_text < invalidate_data < guard_return < process
assert "skipping this display list and retrying the next task" in context

gbi = Path(sys.argv[3]).read_text()
native_count = gbi.index("static std::array<GBISegment, 95> textSegments")
desktop_count = gbi.index("static std::array<GBISegment, 94> textSegments", native_count)
canonical = gbi.index("0x8C1C9814E75E1B4BULL")
native_guard = gbi.index("#if defined(BANANAPAD_NATIVE_SHELL)", canonical)
alternate = gbi.index("0x8EDC2B2BC4D1E3B6ULL", native_guard)
guard_end = gbi.index("#endif", native_guard)
assert canonical < native_guard < alternate < guard_end
assert native_count < desktop_count < canonical
assert "standard FIFO 2.07 values" in gbi[native_guard:guard_end]

cmake = Path(sys.argv[4]).read_text()
shell = cmake.index("if (BANANAPAD_NATIVE_SHELL)")
shell_end = cmake.index("endif()", cmake.index("target_sources(DK64Recompiled", shell))
shell_block = cmake[shell:shell_end]
assert "target_compile_definitions(DK64Recompiled PRIVATE BANANAPAD_NATIVE_SHELL=1)" in shell_block
assert "target_compile_definitions(rt64 PRIVATE BANANAPAD_NATIVE_SHELL=1)" in shell_block
PY

note "renderer task-order contract: pass"

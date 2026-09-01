#!/usr/bin/env python3
"""Derive G3 execution-model manifests from pinned source and ignored AOT output."""

from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT / "worktrees/bananapad-static-macos"
GAME = ROOT / "generated/aot/current-game"
PATCHES = ROOT / "generated/aot/current-patches"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def hex32(value: int) -> str:
    return f"0x{value:08X}"


def write_json(path: Path, value: object) -> None:
    encoded = json.dumps(value, indent=2, sort_keys=True) + "\n"
    path.write_text(encoded, encoding="utf-8")


def parse_function_arrays(source: str) -> dict[str, list[dict[str, object]]]:
    arrays: dict[str, list[dict[str, object]]] = {}
    array_re = re.compile(
        r"static FuncEntry (section_\d+_[A-Za-z0-9_]+)_funcs\[\] = \{(.*?)\n\};",
        re.DOTALL,
    )
    entry_re = re.compile(
        r"\.func = ([A-Za-z0-9_]+), \.offset = (0x[0-9A-Fa-f]+), "
        r"\.rom_size = (0x[0-9A-Fa-f]+)"
    )
    for match in array_re.finditer(source):
        arrays[match.group(1)] = [
            {
                "name": entry.group(1),
                "offset": hex32(int(entry.group(2), 16)),
                "romSize": hex32(int(entry.group(3), 16)),
            }
            for entry in entry_re.finditer(match.group(2))
        ]
    return arrays


def parse_section_table(source: str) -> list[dict[str, object]]:
    arrays = parse_function_arrays(source)
    table_match = re.search(
        r"static SectionTableEntry section_table\[\] = \{(.*?)\n\};", source, re.DOTALL
    )
    if table_match is None:
        raise RuntimeError("generated section table is missing")
    entry_re = re.compile(
        r"\.rom_addr = (0x[0-9A-Fa-f]+), \.ram_addr = (0x[0-9A-Fa-f]+), "
        r"\.size = (0x[0-9A-Fa-f]+), \.funcs = (section_\d+_[A-Za-z0-9_]+)_funcs,.*?"
        r"\.index = (\d+)"
    )
    result = []
    for entry in entry_re.finditer(table_match.group(1)):
        rom = int(entry.group(1), 16)
        ram = int(entry.group(2), 16)
        size = int(entry.group(3), 16)
        array_name = entry.group(4)
        functions = arrays[array_name]
        logical_name = re.sub(r"^section_\d+_", "", array_name)
        result.append(
            {
                "index": int(entry.group(5)),
                "name": logical_name,
                "symbolPrefix": logical_name,
                "decompressedRomStart": hex32(rom),
                "decompressedRomEndExclusive": hex32(rom + size),
                "runtimeRam": hex32(ram),
                "size": hex32(size),
                "functionCount": len(functions),
                "functions": functions,
            }
        )
    return result


def parse_overlay_triggers(source: str) -> dict[str, int]:
    result: dict[str, int] = {}
    case_re = re.compile(r"case (0x[0-9A-Fa-f]+): //([A-Za-z0-9_]+)")
    for match in case_re.finditer(source):
        result[match.group(2)] = int(match.group(1), 16)
    return result


def parse_named_table(source: str, declaration: str) -> list[str]:
    match = re.search(declaration + r"\s*=\s*\{(.*?)\n\};", source, re.DOTALL)
    if match is None:
        raise RuntimeError(f"generated table missing: {declaration}")
    return re.findall(r'\{\s*"([^"]+)"|^\s*"([^"]+)"', match.group(1), re.MULTILINE)


def flattened(values: list[tuple[str, str]]) -> list[str]:
    return [left or right for left, right in values]


def generate_overlays() -> None:
    generated_path = GAME / "RecompiledFuncs/recomp_overlays.inl"
    loader_path = WORKSPACE / "src/game/recomp_api.cpp"
    generated = generated_path.read_text(encoding="utf-8")
    triggers = parse_overlay_triggers(loader_path.read_text(encoding="utf-8"))
    sections = parse_section_table(generated)
    for section in sections:
        name = str(section["name"])
        if name in triggers:
            section["compressedRomTrigger"] = hex32(triggers[name])
            section["sharedReplacementBoundary"] = section["runtimeRam"] == "0x80024000"
    compressed = [section for section in sections if "compressedRomTrigger" in section]
    if len(compressed) != 10:
        raise RuntimeError(f"expected 10 compressed overlay classes, found {len(compressed)}")
    write_json(
        ROOT / "docs/OVERLAYS.json",
        {
            "schemaVersion": 1,
            "source": {
                "generatedTable": str(generated_path.relative_to(ROOT)),
                "generatedTableSha256": sha256(generated_path),
                "loader": str(loader_path.relative_to(ROOT)),
                "loaderSha256": sha256(loader_path),
                "usTomlSha256": sha256(GAME / "us.toml"),
            },
            "invariants": {
                "compressedClassCount": 10,
                "sharedRuntimeDestination": "0x80024000",
                "unknownCompressedTriggerBehavior": "no overlay registration",
            },
            "sections": sections,
        },
    )


def generate_patches() -> None:
    generated_path = PATCHES / "RecompiledPatches/recomp_overlays.inl"
    generated_c_path = PATCHES / "RecompiledPatches/patches.c"
    map_path = PATCHES / "patches/patches.map"
    source = generated_path.read_text(encoding="utf-8")
    arrays = parse_function_arrays(source)
    sections = parse_section_table(source)

    exports = flattened(parse_named_table(source, r"static FunctionExport export_table\[\]"))
    events = flattened(parse_named_table(source, r"static const char\* event_names\[\]"))
    manual_match = re.search(
        r"static const ManualPatchSymbol manual_patch_symbols\[\] = \{(.*?)\n\};",
        source,
        re.DOTALL,
    )
    if manual_match is None:
        raise RuntimeError("manual patch symbol table is missing")
    manual = [
        {"address": hex32(int(address, 16)), "name": name}
        for address, name in re.findall(
            r"\{\s*(0x[0-9A-Fa-f]+),\s*([A-Za-z0-9_]+)\s*\}", manual_match.group(1)
        )
    ]

    classifications = {
        "boot_logos_patches.c": "retained-upstream-enhancement",
        "patches_balancing.c": "retained-upstream-enhancement",
        "patches_debug.c": "required-baseline-correctness",
        "patches_draw.c": "retained-upstream-enhancement",
        "patches_framebuffer.c": "retained-upstream-enhancement",
        "patches_heap.c": "required-baseline-correctness",
        "patches_interpolation.c": "retained-upstream-enhancement",
        "patches_lightning.c": "retained-upstream-enhancement",
        "patches_main.c": "required-baseline-correctness",
        "patches_matrix.c": "retained-upstream-enhancement",
        "patches_ui.c": "retained-upstream-enhancement",
        "print.c": "required-baseline-correctness",
        "sound_options_patches.c": "retained-upstream-enhancement",
        "timing_fixes.c": "required-baseline-correctness",
        "warp_menu.c": "retained-upstream-enhancement",
        "xldtob.c": "required-baseline-correctness",
        "xlitob.c": "required-baseline-correctness",
        "xprintf.c": "required-baseline-correctness",
    }
    patch_sources = []
    for path in sorted((WORKSPACE / "patches").glob("*.c")):
        text = path.read_text(encoding="utf-8", errors="replace")
        definitions = [
            {"kind": kind, "name": name}
            for kind, name in re.findall(
                r"\b(RECOMP_(?:FORCE_)?PATCH)\b[^;{}]*?\b([A-Za-z_][A-Za-z0-9_]*)\s*\(",
                text,
                re.DOTALL,
            )
        ]
        patch_sources.append(
            {
                "path": str(path.relative_to(WORKSPACE)),
                "sha256": sha256(path),
                "classification": classifications.get(path.name, "unknown"),
                "patchDefinitionCount": len(re.findall(r"\bRECOMP_(?:FORCE_)?PATCH\b", text)),
                "eventDefinitionCount": len(re.findall(r"\bRECOMP_EVENT\b", text)),
                "exportDefinitionCount": len(re.findall(r"\bRECOMP_EXPORT\b", text)),
                "patchDefinitions": definitions,
            }
        )

    generated_function_count = len(re.findall(r"^RECOMP_FUNC void ", generated_c_path.read_text(), re.MULTILINE))
    write_json(
        ROOT / "docs/AOT-PATCH-MANIFEST.json",
        {
            "schemaVersion": 1,
            "profile": "N64MODERN_NO_DYNAMIC_CODE=ON",
            "classificationPolicy": {
                "patchSources": "required baseline correctness or retained upstream enhancement; individual route coverage remains tracked by gameplay evidence",
                "desktopFrontendConfigGlue": "excluded from BananaPad native shell",
                "runtimeExecutableMods": "excluded",
            },
            "sourceFiles": patch_sources,
            "generated": {
                "patchC": str(generated_c_path.relative_to(ROOT)),
                "patchCSha256": sha256(generated_c_path),
                "patchMapSha256": sha256(map_path),
                "patchBinarySha256": sha256(PATCHES / "patches/patches.bin"),
                "sectionTableSha256": sha256(generated_path),
                "generatedFunctionCount": generated_function_count,
                "sections": sections,
                "textFunctions": arrays.get("section_1_text", []),
                "replacementFunctions": arrays.get("section_2_recomp_patch", []),
                "exportFunctions": arrays.get("section_3_recomp_export", []),
                "eventFunctions": arrays.get("section_4_recomp_event", []),
                "exports": exports,
                "events": events,
                "manualHostFunctions": manual,
            },
            "registration": {
                "source": "worktrees/bananapad-static-macos/src/main/register_patches.cpp",
                "mechanism": "register_patches plus writable data lookup tables",
            },
        },
    )


def generate_rsp() -> None:
    config_path = GAME / "n_aspMain.toml"
    generated_path = GAME / "rsp/n_aspMain.cpp"
    config_text = config_path.read_text(encoding="utf-8")

    def integer(name: str) -> int:
        match = re.search(rf"^{name}\s*=\s*(0x[0-9A-Fa-f]+|\d+)", config_text, re.MULTILINE)
        if match is None:
            raise RuntimeError(f"RSP config value is missing: {name}")
        return int(match.group(1), 0)

    def string(name: str) -> str:
        match = re.search(rf'^\s*{name}\s*=\s*"([^"]+)"', config_text, re.MULTILINE)
        if match is None:
            raise RuntimeError(f"RSP config value is missing: {name}")
        return match.group(1)

    targets_match = re.search(
        r"extra_indirect_branch_targets\s*=\s*\[(.*?)\]", config_text, re.DOTALL
    )
    if targets_match is None:
        raise RuntimeError("RSP indirect-target list is missing")
    targets = [int(value, 16) for value in re.findall(r"0x[0-9A-Fa-f]+", targets_match.group(1))]
    main_path = WORKSPACE / "src/main/main.cpp"
    write_json(
        ROOT / "docs/RSP-MANIFEST.json",
        {
            "schemaVersion": 1,
            "config": str(config_path.relative_to(ROOT)),
            "configSha256": sha256(config_path),
            "textOffset": hex32(integer("text_offset")),
            "textSize": hex32(integer("text_size")),
            "textAddress": hex32(integer("text_address")),
            "outputFunction": string("output_function_name"),
            "extraIndirectBranchTargets": [hex32(value) for value in targets],
            "generatedSourceSha256": sha256(generated_path),
            "registrationSourceSha256": sha256(main_path),
            "acceptedTaskType": "M_AUDTASK",
            "unknownTaskBehavior": "log and return null; runtime treats missing microcode as fatal",
            "hleFallback": False,
        },
    )


def generate_save() -> None:
    main_path = WORKSPACE / "src/main/main.cpp"
    pi_path = WORKSPACE / "lib/N64ModernRuntime/librecomp/src/pi.cpp"
    eep_path = WORKSPACE / "lib/N64ModernRuntime/librecomp/src/eep.cpp"
    pak_path = WORKSPACE / "lib/N64ModernRuntime/librecomp/src/pak.cpp"
    files_path = WORKSPACE / "lib/N64ModernRuntime/librecomp/src/files.cpp"
    write_json(
        ROOT / "docs/SAVE-MANIFEST.json",
        {
            "schemaVersion": 1,
            "gameId": "DK64",
            "saveType": "Eep16k",
            "guestProbeValue": "0x02",
            "blockSizeBytes": 8,
            "hostLengthBytes": 0x800,
            "hostRelativePath": "saves/DK64.bin",
            "backupSuffix": ".bak",
            "temporarySuffix": ".temp",
            "writeBoundsChecked": True,
            "controllerPak": {
                "supported": False,
                "returnCode": 1,
                "symbolicReturn": "PFS_ERR_NOPACK",
            },
            "sources": {
                str(path.relative_to(ROOT)): sha256(path)
                for path in [main_path, pi_path, eep_path, pak_path, files_path]
            },
        },
    )


def main() -> None:
    required = [
        GAME / "RecompiledFuncs/recomp_overlays.inl",
        PATCHES / "RecompiledPatches/recomp_overlays.inl",
        GAME / "rsp/n_aspMain.cpp",
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise SystemExit("missing ignored G1 output: " + ", ".join(missing))
    generate_overlays()
    generate_patches()
    generate_rsp()
    generate_save()


if __name__ == "__main__":
    main()

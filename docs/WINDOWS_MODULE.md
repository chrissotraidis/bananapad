# Private Windows module builds (draft)

This branch adds a private iOS module route while preserving the existing full
Mac recipe and build scripts. The draft Windows ARM64 and x64 routes are experimental. No matching empty
shell has been published, and the
repository's public binary release pause still applies.

The route requires PadMint's [managed MIPS compiler](https://github.com/chrissotraidis/padmint/pull/180),
[host-selective module routing](https://github.com/chrissotraidis/padmint/pull/182)
and [iOS deployment-floor updates](https://github.com/chrissotraidis/padmint/pull/183). These are draft prerequisites, not a claim about the currently shipped
PadMint release. The shell supports iOS 15; the module must preserve that floor.
Windows players need Visual Studio 2022 Build Tools with Desktop development
with C++ and a Windows SDK. ARM64 tools are preferred on ARM64 Windows; the x64
tools can run under Windows' emulation. Native x64 hardware evidence and emulated
x64 evidence are recorded separately.

The app owns the runtime, renderer, threads, controls and writable game memory.
The private `BananaPadGame.dylib` owns translated CPU code, audio RSP code,
generated overlay tables and compiled patches. Its one exported getter returns
a versioned table of function pointers. The app checks the version, size and
source identity before using any pointer. Generated game symbols remain hidden;
strong patch functions override weak originals inside the module. LiveRecomp,
executable mods and writable native code stay disabled.

`dependencies.lock.json` remains authoritative. Portable preparation verifies
the promoted game and host-tool revisions, each nested Git link, and the exact
known patch stack. It rejects unrelated tracked edits. The generation stage
copies verified source bytes to a temporary directory, preserves replaced output
folders and checks a complete hash ledger before compiling. An explicit
`--source-dir` (or `BANANAPAD_SOURCE_DIR`) is developer-only read-only cache reuse;
it requires the matching `n64recomp-host` checkout beside the game checkout and
never fetches, repairs or reapplies patches there.

The Windows backend uses Python, CMake/Ninja, MSVC host generators, PadMint's
iOS LLVM toolchain and its separately pinned MIPS compiler. ROM normalization
and bounded gzip decompression use Python's standard library. GNU make, Rust,
Apple's SDK, signing credentials and symlink privileges are not player
prerequisites for this route.

Maintainers can build the empty app on macOS with:

```sh
python3 scripts/build-module-shell.py --jobs 4
```

The portable backend is `scripts/build-game-module.py`. PadMint supplies
`--rom`, `--toolchain`, `--build-dir`, `--jobs`, and its managed tool environment.
It inserts the result at the app root, preserving the supplied shell's contents.
Use a matching local shell through PadMint's `--app` while publication is gated.

Current checks include byte-for-byte private decompression against the pinned
C++ decompressor, synthetic malformed gzip and expansion-limit tests, source
preservation and ledger tests, a native loader/patch-precedence fixture, and
actual private Mac source generation. Public CI builds only pinned open-source
generators and synthetic fixtures on native Windows ARM64, Windows x64 and
macOS. It uploads no private input, generated game code or personal app.

Validation recorded on 26 October 2026:

- At `0718979`, the actual private Mac shell/module pair passes strict imports
  (125 app callbacks and seven known runtime names), the sole-getter export check,
  matching source identity and physical-device iOS 15 minimum checks. Insertion
  preserves all 248 base archive entries and adds only the private module.
- The packaged development PadMint code from `e70b542` ran the actual backend
  on Windows 11 ARM64 using native ARM64 MSVC generators and LLVM 21.1.8. It
  completed in 105 seconds after source seeding and SDK preparation. Public
  source checkouts began unpatched at their locked commits, reused verified
  local Git objects, and used the normal preparation/patch replay. Managed tools
  were cached; no source-cache override was used.
- A separate backend build used x64 MSVC generators and x64 LLVM under Windows
  ARM64 emulation, completing in 132 seconds. Compiler, generator, LLVM compiler
  and linker PE headers were checked as x64; native ARM64 coordinator tools were
  retained. Both Windows outputs pass the same import, identity, iOS 15 and IPA
  readback checks. This is not native-x64-hardware private-build evidence.
- The unchanged full static Mac route also compiled and passed package checks
  at `69076b8`, using task-owned prepared sources and the original pinned
  generator/compiler path. The earlier static worktree was preserved.
- Twenty portable behavior/source tests and 15 synthetic loader/patch-precedence
  cases pass. The host-specific Visual Studio query includes regressions for a
  newer ARM-only installation hiding an older eligible x64 installation, native
  ARM64 preference, and ARM64 fallback to x64. Native Windows x64/ARM64 public
  generator CI passes without game inputs.

- The complete packaged `padmint build` command passed from `d3c750d` in
  73 seconds on Windows ARM64. It used the bundled x64 Python, the standard
  recipe and existing managed tools/source cache, with no source override. The
  Visual Studio prerequisite passed before the build. Its 308-file output ledger
  exactly matches the earlier ARM64 backend; all 279 checked text files from
  both Windows toolchains match Mac after newline normalization. Final readback
  reconfirms the iOS 15 floor, source identity, imports and unchanged shell.

Signing, iOS loading, gameplay and a full private build on native x64 hardware
remain separate gates. A passing source test or cross-compile does not establish
gameplay.
Before any future game release, PadMint's current-main `scripts/player-check.sh`
must pass before tagging and again after publication, in addition to the
repository's artifact audit and explicit publication approval.

Unicode path follow-up at `43048eb`: the Windows ARM64 private backend passed
with Unicode source, work, ROM and temporary paths, using existing verified
public source and tool caches. All 274 generated code/header files matched the
previous private output byte for byte. The matching new shell/module pair
passed strict imports, sole-export and iOS 15 checks; insertion preserved all
eight files in the raw empty shell. Independent Apple `nm`/`otool` and archive
readback passed, and the original ROM stayed unchanged. This was not a fresh
default player installation or a physical-device test.

The fix uses per-process UTF-8 manifests for host generators, Unicode Visual
Studio environment capture, explicit UTF-8 Git path decoding, and UTF-8 Python
entrypoints/CMake children. It changes no system locale setting. Twenty-two
focused tests passed on Apple Python 3.9 and bundled Windows Python. Native
Windows x64/ARM64 and macOS CI passed public Unicode CLI/TOML path and generation
checks, including manifest readback on Windows. These fixtures check generated
CPU function presence and RSP BREAK output, not execution of the emitted CPU.

Packaged PadMint release check (2026-11-01): the PadMint 0.5.27 Windows ZIP,
with its bundled Python on Windows 11 ARM64, ran `padmint build bananapad
--target ios` from a fresh clone of this branch at `39e5b14`, the supported ROM
and an empty shell built on a Mac from that same revision. It finished in 108
seconds with warm managed tools and recorded `personal-only`. All 248 shell
entries stayed unchanged and only `BananaPadGame.dylib` was added; the IPA's
CRCs are valid. With this run the recipe moves from `draft-untested` to
`experimental`. A shell built at `0718979` has a different module identity
and must not be paired with this revision. Device launch is still untested.

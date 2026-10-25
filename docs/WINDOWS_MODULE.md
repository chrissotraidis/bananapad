# Private Windows module builds (draft)

This branch adds a private iOS module route while preserving the existing full
Mac recipe and build scripts. Windows support remains planned until an actual
packaged build has passed. No matching empty shell has been published, and the
repository's public binary release pause still applies.

The route requires PadMint's managed MIPS compiler and iOS deployment-floor
updates. These are draft prerequisites, not a claim about the currently shipped
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

Actual shell/module imports, full packaged Windows output, default Mac build
regression, signing, iOS loading and gameplay acceptance are separate remaining
gates. A passing source test or cross-compile does not establish gameplay.
Before any future game release, PadMint's current-main `scripts/player-check.sh`
must pass before tagging and again after publication, in addition to the
repository's artifact audit and explicit publication approval.

#!/usr/bin/env python3
"""Run unchanged build entrypoints in disposable fixtures, never real builds.

Only the device LLVM presence checks read host paths. Those files are never
executed or copied: fake CMake always stops before compilation.
Run with /usr/bin/python3 and python3; uses only the Python 3.9 standard library.
"""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
VARIANTS = ("host", "macos-static", "device-unsigned", "device-signed")
SCRIPTS = {
    "host": "build-host-tools.sh",
    "macos": "build-bananapad-macos.sh",
    "device": "build-bananapad-ios-device.sh",
}
BUILD_STOP, CONFIGURE_STOP, SOURCE_STOP = 73, 74, 75
STUB = r'''
import json
import os
from pathlib import Path
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["FIXTURE_LOG"], "a") as log:
    log.write(json.dumps(sys.argv) + "\n")
if name in ("check-prerequisites.sh", "prepare-bananapad-sdl2.sh"):
    sys.exit(0)
if name == "verify-sources.sh":
    sys.exit(75 if os.environ["FIXTURE_FAILURE"] == "source" else 0)
if name == "sysctl" and args == ["-n", "hw.ncpu"]:
    print("7")
elif name == "jq" and args[:2] == ["-er", ".upstream.promoted.commit"]:
    print(json.loads(Path(args[2]).read_text())["upstream"]["promoted"]["commit"])
elif name == "git" and args[2:] == ["rev-parse", "HEAD"]:
    print(os.environ["FIXTURE_COMMIT"])
elif name == "git" and args[2:5] == ["apply", "--reverse", "--check"]:
    pass
elif name == "cmake":
    if args[0] == "--build":
        sys.exit(73)
    if args[0] != "-S":
        sys.exit("unexpected CMake invocation")
    sys.exit(74 if os.environ["FIXTURE_FAILURE"] == "configure" else 0)
else:
    sys.exit("forbidden fixture command: " + name + " " + repr(args))
'''


class BuildParallelismTests(unittest.TestCase):
    maxDiff = None

    def run_fixture(self, variant, limit=None, failure=""):
        # Keep all generated fixtures inside this sidecar's shared write scope.
        with tempfile.TemporaryDirectory(prefix=".parallelism-", dir=ROOT) as temporary:
            root = Path(temporary)
            scripts = root / "scripts"
            (scripts / "lib").mkdir(parents=True)
            shutil.copyfile(ROOT / "scripts/lib/common.sh", scripts / "lib/common.sh")
            shutil.copyfile(ROOT / "dependencies.lock.json", root / "dependencies.lock.json")
            kind = variant.split("-")[0]
            entrypoint = scripts / SCRIPTS[kind]
            shutil.copyfile(ROOT / "scripts" / SCRIPTS[kind], entrypoint)
            self.assertEqual(entrypoint.read_bytes(), (ROOT / "scripts" / SCRIPTS[kind]).read_bytes())
            tools = root / "tools"
            tools.mkdir()
            stub = tools / "stub"
            stub.write_text("#!" + sys.executable + "\n" + STUB)
            stub.chmod(0o755)
            for name in ("cmake", "sysctl", "git", "jq", "plutil", "codesign", "install_name_tool",
                         "xcodebuild", "xcrun", "clang", "clang++", "ninja", "zip", "otool"):
                (tools / name).symlink_to(stub)
            for name in ("check-prerequisites.sh", "verify-sources.sh", "prepare-bananapad-sdl2.sh",
                         "audit-ios-package.sh"):
                (scripts / name).symlink_to(stub)

            def touch(relative, executable=False):
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture only\n")
                if executable:
                    path.chmod(0o755)
                return str(path)

            workspace = root / "workspace with spaces"
            touch("workspace with spaces/.git")
            touch("workspace with spaces/rsp/.keep")
            touch("workspace with spaces/patches/.keep")
            for directory in ("patches/upstream", "patches/bananapad"):
                (root / directory).mkdir(parents=True)
            touch("patches/bananapad/fixture.patch")
            game = root / "generated/aot/current-game"
            patches = root / "generated/aot/current-patches"
            touch("generated/aot/current-game/manifest.sha256")
            touch("generated/aot/current-game/RecompiledFuncs/fixture.c")
            touch("generated/aot/current-game/rsp/n_aspMain.cpp")
            touch("generated/aot/current-patches/manifest.sha256")
            for name in ("patches.c", "funcs.h", "recomp_overlays.inl"):
                touch("generated/aot/current-patches/RecompiledPatches/" + name)
            touch("generated/aot/current-patches/patches/patches.elf")
            touch("generated/aot/current-patches/patches/patches.bin")
            rom = touch("generated/rom/donkeykong64.decompressed.us.z64")
            host_tools = root / "generated/build/host-tools"
            for name in ("N64Recomp", "RSPRecomp"):
                touch("generated/build/host-tools/" + name, executable=True)
            file_to_c = touch("fixture-native/file_to_c", executable=True)
            spirv = touch("fixture-native/spirv_cross_msl", executable=True)
            touch("generated/dependencies/sdl2-bananapad/CMakeLists.txt")
            touch("ref/paperpad/ref/SDL2/include/SDL.h")
            touch("ref/paperpad/build-macos-sdl2/libSDL2.a")
            build = root / "output with spaces"
            if failure == "source" and kind == "device":
                (workspace / ".git").unlink()
            log = root / "argv.jsonl"
            commit = json.loads((root / "dependencies.lock.json").read_text())["upstream"]["promoted"]["commit"]
            # Whitelist environment; inherited build/signing/Python/shell settings
            # cannot influence this subprocess. Empty and unset limits differ.
            env = {
                "PATH": str(tools) + ":/usr/bin:/bin:/usr/sbin:/sbin",
                "TMPDIR": str(root), "LC_ALL": "C", "PYTHONDONTWRITEBYTECODE": "1",
                "FIXTURE_LOG": str(log), "FIXTURE_COMMIT": commit, "FIXTURE_FAILURE": failure,
                "BANANAPAD_WORKSPACE": str(workspace), "BANANAPAD_BUILD_DIR": str(build),
                "BANANAPAD_GAME_SET": str(game), "BANANAPAD_PATCH_SET": str(patches),
                "BANANAPAD_DECOMPRESSED_ROM": rom, "BANANAPAD_HOST_TOOLS": str(host_tools),
                "BANANAPAD_FILE_TO_C": file_to_c, "BANANAPAD_SPIRV_CROSS_MSL": spirv,
                "BANANAPAD_MACOS_PROFILE": "static",
            }
            if limit is not None:
                env["CMAKE_BUILD_PARALLEL_LEVEL"] = limit
            if variant == "device-signed":
                env["BANANAPAD_DEVELOPMENT_TEAM"] = "FIXTURETEAM"
            result = subprocess.run(["/bin/bash", str(entrypoint)], cwd=root, env=env,
                                    text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)
            invocations = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
            # The log retains argv[0] and every argument; compare command names
            # without coupling assertions to the disposable fixture directory.
            calls = [[Path(argv[0]).name] + argv[1:] for argv in invocations]
            cmake = [call for call in calls if call[0] == "cmake"]
            sysctl = [call for call in calls if call[0] == "sysctl"]
            message = variant + " limit=" + repr(limit) + " failure=" + failure + "\n" + result.stderr
            self.assertFalse(list(root.rglob("*.app")), message)
            self.assertFalse(list(root.rglob("*.ipa")), message)
            self.assertFalse(any(call[0] in ("codesign", "plutil", "install_name_tool", "zip", "otool",
                                            "audit-ios-package.sh", "xcodebuild", "xcrun", "clang",
                                            "clang++", "ninja") for call in calls), message)
            if limit and (not limit.isascii() or not limit.isdecimal() or limit.startswith("0")):
                self.assertNotEqual(result.returncode, 0, message)
                self.assertIn("CMAKE_BUILD_PARALLEL_LEVEL must be a positive whole number without leading zeros", result.stderr, message)
                self.assertEqual(calls, [], message)
                self.assertFalse(build.exists(), message)
                self.assertFalse((root / "worktrees").exists(), message)
                self.assertFalse((workspace / "N64Recomp").exists(), message)
                return
            if failure == "source":
                self.assertEqual(result.returncode, 1 if kind == "device" else SOURCE_STOP, message)
                if kind == "device":
                    self.assertIn("prepared BananaPad worktree is missing", result.stderr, message)
                    self.assertEqual(calls, [["jq", "-er", ".upstream.promoted.commit",
                                             str(root / "dependencies.lock.json")]], message)
                else:
                    self.assertEqual(calls, [["check-prerequisites.sh"], ["verify-sources.sh"]], message)
                self.assertEqual(cmake, [], message)
                self.assertEqual(sysctl, [], message)
                self.assertFalse(build.exists(), message)
                return
            self.assertEqual(result.returncode, CONFIGURE_STOP if failure == "configure" else BUILD_STOP, message)
            expected_configure = self.configure_argv(kind, variant, root, workspace, build, file_to_c, spirv)
            expected_build = ["cmake", "--build", str(host_tools if kind == "host" else build)]
            if kind == "device":
                expected_build += ["--config", "Release"]
            expected_build += ["--target"] + (["N64Recomp", "RSPRecomp"] if kind == "host" else ["DK64Recompiled"])
            expected_build += ["-j", limit or "7"]
            if variant == "device-signed":
                expected_build += ["--", "-allowProvisioningUpdates", "-allowProvisioningDeviceRegistration"]
            self.assertEqual(cmake, [expected_configure] + ([] if failure == "configure" else [expected_build]), message)
            self.assertEqual(sysctl, [] if limit or failure == "configure" else [["sysctl", "-n", "hw.ncpu"]], message)

    def configure_argv(self, kind, variant, root, workspace, build, file_to_c, spirv):
        llvm = "/opt/homebrew/opt/llvm@18/bin"
        if kind == "host":
            return ["cmake", "-S", str(root / "ref/toolchain/n64recomp-host"), "-B",
                    str(root / "generated/build/host-tools"), "-G", "Ninja", "-DCMAKE_BUILD_TYPE=Release",
                    "-DCMAKE_C_COMPILER=clang", "-DCMAKE_CXX_COMPILER=clang++"]
        argv = ["cmake", "-S", str(workspace), "-B", str(build), "-G"]
        if kind == "macos":
            argv += ["Ninja", "-DCMAKE_BUILD_TYPE=Release", "-DCMAKE_C_COMPILER=clang", "-DCMAKE_CXX_COMPILER=clang++",
                     "-DCMAKE_AR=" + llvm + "/llvm-ar", "-DPATCHES_C_COMPILER=" + llvm + "/clang",
                     "-DPATCHES_LD=" + llvm + "/ld.lld", "-DCMAKE_OSX_ARCHITECTURES=arm64",
                     "-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0", "-DN64MODERN_NO_DYNAMIC_CODE=ON",
                     "-DCMAKE_PREFIX_PATH=/opt/homebrew/opt/curl", "-DCURL_ROOT=/opt/homebrew/opt/curl"]
            argv += ["-DBANANAPAD_SDL2_SOURCE_DIR=" + str(root / "ref/paperpad/ref/SDL2"),
                     "-DBANANAPAD_SDL2_STATIC_LIBRARY=" + str(root / "ref/paperpad/build-macos-sdl2/libSDL2.a"),
                     "-DBANANAPAD_NATIVE_SHELL=ON", "-DBANANAPAD_APPLE_CORE_DIR=" + str(root / "apple/core")]
            return argv
        flags = "-ffile-prefix-map={0}=BananaPadSource -fdebug-prefix-map={0}=BananaPadSource -ffile-prefix-map={1}=BananaPadProject -fdebug-prefix-map={1}=BananaPadProject".format(workspace, root)
        argv += ["Xcode", "-DCMAKE_SYSTEM_NAME=iOS", "-DCMAKE_OSX_SYSROOT=iphoneos", "-DCMAKE_OSX_ARCHITECTURES=arm64",
                 "-DCMAKE_OSX_DEPLOYMENT_TARGET=15.0"]
        argv += ["-DCMAKE_" + language + "_FLAGS=" + flags for language in ("C", "CXX", "OBJC", "OBJCXX")]
        if variant == "device-signed":
            argv += ["-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=YES", "-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=YES",
                     "-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_STYLE=Automatic", "-DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=FIXTURETEAM"]
        else:
            argv += ["-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO"]
        return argv + ["-DVCPKG_TARGET_TRIPLET=arm64-ios", "-DBANANAPAD_NATIVE_SHELL=ON",
                       "-DBANANAPAD_APPLE_CORE_DIR=" + str(root / "apple/core"), "-DBANANAPAD_APPLE_APP_DIR=" + str(root / "apple/app"),
                       "-DBANANAPAD_SDL2_SOURCE_DIR=" + str(root / "generated/dependencies/sdl2-bananapad"),
                       "-DBANANAPAD_SDL2_STATIC_LIBRARY=", "-DN64MODERN_NO_DYNAMIC_CODE=ON", "-DRT64_BUILD_TOOLS=OFF",
                       "-DFILE_TO_C_PATH=" + file_to_c, "-DSPIRV_CROSS_MSL_PATH=" + spirv,
                       "-DPATCHES_C_COMPILER=" + llvm + "/clang", "-DPATCHES_LD=" + llvm + "/ld.lld"]

    def test_default(self):
        for variant in VARIANTS:
            for limit in (None, ""):
                with self.subTest(variant=variant, limit=limit):
                    self.run_fixture(variant, limit)

    def test_env2(self):
        for variant in VARIANTS:
            with self.subTest(variant=variant):
                self.run_fixture(variant, "2")

    def test_other_valid_limits(self):
        for variant in VARIANTS:
            for limit in ("1", "12", "999999999999999999999999999999"):
                with self.subTest(variant=variant, limit=limit):
                    self.run_fixture(variant, limit)

    def test_invalid(self):
        for variant in VARIANTS:
            for limit in ("0", "00", "02", "-1", "+2", "1.5", "2e1", " ", " 2", "2 ", "2\n", "2x", "2;exit", "\u0662"):
                with self.subTest(variant=variant, limit=limit):
                    self.run_fixture(variant, limit)

    def test_early_failures(self):
        for variant in VARIANTS:
            for failure in ("source", "configure"):
                for limit in (None, "", "2"):
                    with self.subTest(variant=variant, failure=failure, limit=limit):
                        self.run_fixture(variant, limit, failure)


if __name__ == "__main__":
    unittest.main()

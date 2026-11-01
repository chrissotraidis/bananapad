#!/usr/bin/env python3
"""Build the opt-in empty iOS shell on a Mac, without changing the full build."""
import argparse
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))
from module_build import ROOT, run


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--jobs', type=int, choices=range(1, 17), default=4)
    args = parser.parse_args()
    if sys.platform != 'darwin':
        parser.error('The maintainer shell requires macOS and Xcode.')
    spec = importlib.util.spec_from_file_location('banana_source_setup', ROOT / 'scripts/setup-source.py')
    setup = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(setup)
    source = setup.prepare()
    env = dict(os.environ, CMAKE_BUILD_PARALLEL_LEVEL=str(args.jobs))
    run(ROOT / 'scripts/prepare-bananapad-sdl2.sh', env=env)
    host, build = ROOT / 'work/shell-host-tools', ROOT / 'work/module-shell'
    run('cmake', '--fresh', '-S', ROOT / 'cmake/shell-host-tools', '-B', host, '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release', f'-DBANANAPAD_SOURCE={source}', env=env)
    run('cmake', '--build', host, '--target', 'file_to_c', 'spirv_cross_msl', '--parallel', args.jobs, env=env)
    run('cmake', '--fresh', '-S', source, '-B', build, '-G', 'Xcode',
        '-DCMAKE_SYSTEM_NAME=iOS', '-DCMAKE_OSX_SYSROOT=iphoneos', '-DCMAKE_OSX_ARCHITECTURES=arm64',
        '-DCMAKE_OSX_DEPLOYMENT_TARGET=15.0', '-DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO',
        '-DBANANAPAD_MODULE_SHELL=ON', '-DBANANAPAD_NATIVE_SHELL=ON',
        f'-DBANANAPAD_APPLE_CORE_DIR={ROOT / "apple/core"}',
        f'-DBANANAPAD_APPLE_APP_DIR={ROOT / "apple/app"}',
        f'-DBANANAPAD_SDL2_SOURCE_DIR={ROOT / "generated/dependencies/sdl2-bananapad"}',
        '-DN64MODERN_NO_DYNAMIC_CODE=ON', '-DRT64_BUILD_TOOLS=OFF',
        f'-DFILE_TO_C_PATH={host / "bin/file_to_c"}',
        f'-DSPIRV_CROSS_MSL_PATH={host / "bin/spirv_cross_msl"}',
        f'-DPython3_EXECUTABLE={sys.executable}', env=env)
    run('cmake', '--build', build, '--config', 'Release', '--target', 'DK64Recompiled',
        '--parallel', args.jobs, env=env)
    print(f'Empty shell: {build / "Release/BananaPad.app"}')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))

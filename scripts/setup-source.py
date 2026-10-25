#!/usr/bin/env python3
"""Prepare the existing promoted source pins, preserving unknown local changes."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'work/module-sources/dk64'
MODULES = ('lib/N64ModernRuntime', 'lib/dk64_decomp', 'lib/rt64',
           'lib/rt64/src/contrib/hlslpp', 'lib/rt64/src/contrib/nativefiledialog-extended',
           'lib/rt64/src/contrib/plume')


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def git(path, *args):
    return subprocess.check_output(['git', '-C', str(path), *args],
                                   env=dict(os.environ, GIT_OPTIONAL_LOCKS='0'))


def revision(path):
    return git(path, 'rev-parse', 'HEAD').decode().strip()


def links(path):
    result = {}
    for record in git(path, 'ls-tree', '-rz', 'HEAD').split(b'\0'):
        if record.startswith(b'160000 '):
            metadata, name = record.split(b'\t', 1)
            result[name.decode()] = metadata.split()[2].decode()
    return result


def required(name, module_only):
    return not module_only or name in MODULES or name.startswith('lib/N64ModernRuntime/')


def repositories(source, module_only=False, existing_only=False):
    """Every dependency is verified against its parent's pinned Git object."""
    found = {'': source}
    def visit(path, prefix=''):
        for relative, pin in links(path).items():
            name = prefix + relative
            child = source / name
            if existing_only and not (child / '.git').exists():
                continue
            if not existing_only and not required(name, module_only):
                continue
            if not (child / '.git').exists() or revision(child) != pin:
                raise ValueError(f'Preserving missing or differently pinned dependency: {child}')
            found[name] = child
            visit(child, name + '/')
    visit(source)
    return found


def patch_stack(source):
    return [f'{source}|{patch}' for folder in ('upstream', 'bananapad', 'module')
            for patch in sorted((ROOT / 'patches' / folder).glob('*.patch'))]


def replay_module():
    spec = importlib.util.spec_from_file_location('banana_patch_replay', ROOT / 'scripts/apply-source-patches.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_tracked_sources(source, repos, stack):
    allowed = set()
    for item in stack:
        _folder, patch = item.split('|', 1)
        allowed.update(re.findall(r'^(?:--- a/|\+\+\+ b/)([^\t\n]+)', Path(patch).read_text(), re.M))
    for prefix, path in repos.items():
        dirty = git(path, 'diff', 'HEAD', '--name-only', '--ignore-submodules=all').decode().splitlines()
        for name in dirty:
            combined = f'{prefix}/{name}' if prefix else name
            if combined in allowed:
                continue
            file = path / name
            original = git(path, 'show', f'HEAD:{name}')
            if (file.is_file() and not file.is_symlink()
                    and file.read_bytes().replace(b'\r\n', b'\n') == original.replace(b'\r\n', b'\n')):
                continue
            raise ValueError(f'Preserving unexpected tracked source changes: {file}')


def host_source(source):
    return source.parent / 'n64recomp-host'


def verify(module_only=False, source=None):
    source = (Path(source) if source is not None else SOURCE).resolve()
    pins = json.loads((ROOT / 'dependencies.lock.json').read_text())['references']
    host = host_source(source)
    if revision(source) != pins['dk64Recompiled']['commit'] or revision(host) != pins['n64RecompHostTools']['commit']:
        raise ValueError('Public source or host-generator revision differs from dependencies.lock.json')
    stack = patch_stack(source)
    verify_tracked_sources(source, repositories(source, module_only), stack)
    verify_tracked_sources(host, repositories(host), [])
    replay_module().apply(source, stack, verify_only=True)
    return source


def clone(path, pin):
    if not (path / '.git').exists():
        if path.exists() and any(path.iterdir()):
            raise ValueError(f'Preserving non-Git source folder: {path}')
        path.parent.mkdir(parents=True, exist_ok=True)
        run('git', 'clone', '--no-checkout', '-c', 'core.autocrlf=false', pin['url'], path)
        run('git', '-C', path, 'checkout', '--detach', pin['commit'])
    if revision(path) != pin['commit']:
        raise ValueError(f'Preserving source with a different revision: {path}')


def select_source(source=None):
    # Explicit prepared source reuse never fetches, patches, or changes a checkout.
    return verify(module_only=True, source=source) if source is not None else prepare(module_only=True)


def prepare(module_only=False):
    pins = json.loads((ROOT / 'dependencies.lock.json').read_text())['references']
    source, host = SOURCE, host_source(SOURCE)
    clone(source, pins['dk64Recompiled'])
    clone(host, pins['n64RecompHostTools'])
    stack = patch_stack(source)
    verify_tracked_sources(source, repositories(source, existing_only=True), stack)
    verify_tracked_sources(host, repositories(host, existing_only=True), [])
    if module_only:
        run('git', '-C', source, '-c', 'core.autocrlf=false', 'submodule', 'update', '--init', '--',
            'lib/N64ModernRuntime', 'lib/dk64_decomp', 'lib/rt64')
        run('git', '-C', source, '-c', 'core.autocrlf=false', 'submodule', 'update', '--init', '--recursive', '--', 'lib/N64ModernRuntime')
        run('git', '-C', source / 'lib/rt64', '-c', 'core.autocrlf=false', 'submodule', 'update', '--init', '--',
            'src/contrib/hlslpp', 'src/contrib/nativefiledialog-extended', 'src/contrib/plume')
    else:
        run('git', '-C', source, '-c', 'core.autocrlf=false', 'submodule', 'update', '--init', '--recursive')
    run('git', '-C', host, '-c', 'core.autocrlf=false', 'submodule', 'update', '--init', '--recursive')
    verify_tracked_sources(source, repositories(source, module_only), stack)
    verify_tracked_sources(host, repositories(host), [])
    replay_module().apply(source, stack)
    return source


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--module-only', action='store_true')
    args = parser.parse_args()
    try:
        print(prepare(args.module_only))
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))

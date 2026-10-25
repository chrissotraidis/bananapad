"""Portable build checks use only hand-written synthetic data."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zlib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
import module_build as module
spec = importlib.util.spec_from_file_location('source_setup', ROOT / 'scripts/setup-source.py')
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


def block(data):
    stream = zlib.compressobj(wbits=31)
    return stream.compress(data) + stream.flush()


class DecoderTests(unittest.TestCase):
    def test_block_with_padding(self):
        for padding in (b'', b'\0' * 15):
            self.assertEqual(module.decompress_gzip_block(block(b'example') + padding), b'example')

    def test_bad_headers_crc_size_and_truncation(self):
        valid = block(b'example')
        crc = bytearray(valid); crc[-8] ^= 1
        size = bytearray(valid); size[-4] ^= 1
        for data in (b'', b'bad123', valid[:-1], bytes(crc), bytes(size)):
            with self.subTest(data=data), self.assertRaises((ValueError, zlib.error)):
                module.decompress_gzip_block(data)

    def test_expansion_is_bounded(self):
        with self.assertRaises(ValueError):
            module.decompress_gzip_block(block(b'a' * (16 * 1024 * 1024 + 1)))

    def test_normalize_orders_and_original_unchanged(self):
        canonical = b'\x80\x37\x12\x40example!'
        lock = json.dumps({'rom': {'size': len(canonical), 'sha1': hashlib.sha1(canonical).hexdigest()}})
        with mock.patch.object(Path, 'read_text', return_value=lock):
            for size in (1, 2, 4):
                data = b''.join(canonical[n:n + size][::-1] for n in range(0, len(canonical), size))
                original = bytes(data)
                self.assertEqual(module.normalize_rom(data), canonical)
                self.assertEqual(data, original)
            with self.assertRaises(ValueError):
                module.normalize_rom(canonical[:-1])
            with self.assertRaises(ValueError):
                module.normalize_rom(canonical[:-1] + b'?')


class GeneratedTests(unittest.TestCase):
    def test_ledger_catches_changed_deleted_added_and_stale(self):
        with tempfile.TemporaryDirectory() as temporary, mock.patch.object(module, 'identity', return_value='contract'):
            folder = Path(temporary)
            files = ['RecompiledFuncs/lookup.cpp', 'RecompiledFuncs/recomp_overlays.inl',
                     'RecompiledFuncs/code.c', 'rsp/n_aspMain.cpp', 'RecompiledPatches/patches.c',
                     'RecompiledPatches/patches_bin.c']
            for name in files:
                file = folder / name
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_bytes(b'/* synthetic */\n')
            def stamp():
                (folder / 'module-inputs.json').write_text(json.dumps({'contract': 'contract', 'outputs': module.output_hashes(folder)}))
            stamp()
            module.check_generated(folder)
            (folder / files[0]).write_bytes(b'changed')
            with self.assertRaises(ValueError): module.check_generated(folder)
            stamp()
            (folder / files[0]).unlink()
            with self.assertRaises(ValueError): module.check_generated(folder)
            stamp()
            with self.assertRaises(ValueError): module.check_generated(folder)
            (folder / files[0]).write_bytes(b'/* synthetic */\n')
            stamp()
            (folder / 'unexpected.c').write_bytes(b'new')
            with self.assertRaises(ValueError): module.check_generated(folder)
            stamp()
            with mock.patch.object(module, 'identity', return_value='new-contract'), self.assertRaises(ValueError):
                module.check_generated(folder)

    def test_make_flags_rejects_unreviewed_variable(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'Makefile'
            path.write_text('GBI_DEFINE := -DF3DEX_GBI\nCPPFLAGS := -nostdinc $(GBI_DEFINE)\n')
            self.assertEqual(module.make_flags(path, 'CPPFLAGS'), ['-nostdinc', '-DF3DEX_GBI'])
            path.write_text('CPPFLAGS := $(UNREVIEWED)\n')
            with self.assertRaises(ValueError): module.make_flags(path, 'CPPFLAGS')

    def test_embedded_patch_has_exact_bytes_and_size(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            module.embed_patch(bytes([0, 127, 128, 255]), folder)
            self.assertIn('{0,127,-128,-1}', (folder / 'patches_bin.c').read_text())
            self.assertIn('sizeof(bk_patches_bin)', (folder / 'patches_bin.c').read_text())
            self.assertIn('extern const size_t bk_patches_bin_size', (folder / 'patches_bin.h').read_text())


class SourceTests(unittest.TestCase):
    def test_unrelated_dirty_source_is_preserved_and_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary)
            subprocess.run(['git', 'init', '-q', str(folder)], check=True)
            (folder / 'input.cpp').write_bytes(b'one\r\ntwo\r\n')
            subprocess.run(['git', '-C', str(folder), '-c', 'core.autocrlf=false', 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(folder), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                            'commit', '-qm', 'synthetic input'], check=True)
            repos = {'': folder}
            (folder / 'input.cpp').write_bytes(b'one\ntwo\n')
            setup.verify_tracked_sources(folder, repos, [])
            (folder / 'input.cpp').write_bytes(b'user edit\n')
            with self.assertRaises(ValueError): setup.verify_tracked_sources(folder, repos, [])
            self.assertEqual((folder / 'input.cpp').read_bytes(), b'user edit\n')

    def test_selected_staging_keeps_verified_patch_bytes(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary) / 'source'
            folder.mkdir()
            subprocess.run(['git', 'init', '-q', str(folder)], check=True)
            (folder / 'header.h').write_bytes(b'original\n')
            subprocess.run(['git', '-C', str(folder), 'add', '.'], check=True)
            subprocess.run(['git', '-C', str(folder), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                            'commit', '-qm', 'synthetic input'], check=True)
            # setup-source verifies this reviewed patch before export_files is called.
            (folder / 'header.h').write_bytes(b'reviewed patched header\n')
            (folder / 'untracked.h').write_bytes(b'not an input\n')
            destination = Path(temporary) / 'stage'
            module.export_files(folder, destination, ['.'])
            self.assertEqual((destination / 'header.h').read_bytes(), b'reviewed patched header\n')
            self.assertFalse((destination / 'untracked.h').exists())

    def test_explicit_source_cache_never_prepares_or_repairs(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source, host, recipe = root / 'dk64', root / 'n64recomp-host', root / 'recipe'
            recipe.mkdir()
            for repo in (source, host):
                repo.mkdir()
                subprocess.run(['git', 'init', '-q', str(repo)], check=True)
                (repo / 'input.cpp').write_bytes(b'original\n')
                subprocess.run(['git', '-C', str(repo), '-c', 'core.autocrlf=false', 'add', '.'], check=True)
                subprocess.run(['git', '-C', str(repo), '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                                'commit', '-qm', 'synthetic input'], check=True)
            pins = {'references': {'dk64Recompiled': {'commit': setup.revision(source)},
                                    'n64RecompHostTools': {'commit': setup.revision(host)}}}
            (recipe / 'dependencies.lock.json').write_text(json.dumps(pins))
            replay = setup.replay_module()
            def snapshot():
                return {str(p.relative_to(root)): p.read_bytes() for repo in (source, host)
                        for p in repo.rglob('*') if p.is_file()}
            with mock.patch.object(setup, 'ROOT', recipe), mock.patch.object(setup, 'replay_module', return_value=replay), \
                    mock.patch.object(setup, 'prepare', side_effect=AssertionError('explicit cache must not prepare')):
                before = snapshot()
                self.assertEqual(setup.select_source(source), source.resolve())
                self.assertEqual(snapshot(), before)
                patch = recipe / 'patches/module/001.patch'
                patch.parent.mkdir(parents=True)
                patch.write_bytes(b'--- a/input.cpp\n+++ b/input.cpp\n@@ -1 +1 @@\n-original\n+patched\n')
                with self.assertRaisesRegex(ValueError, 'not fully applied'):
                    setup.select_source(source)
                self.assertEqual(snapshot(), before)
                (source / 'input.cpp').write_bytes(b'user edit\n')
                before = snapshot()
                with self.assertRaisesRegex(ValueError, 'Preserving unexpected'):
                    setup.select_source(source)
                self.assertEqual(snapshot(), before)
                pins['references']['dk64Recompiled']['commit'] = '0' * 40
                (recipe / 'dependencies.lock.json').write_text(json.dumps(pins))
                with self.assertRaisesRegex(ValueError, 'differs'):
                    setup.select_source(source)
                self.assertEqual(snapshot(), before)


if __name__ == '__main__':
    unittest.main()

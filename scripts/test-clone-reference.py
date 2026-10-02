#!/usr/bin/env python3
"""Use a tiny local Git fixture; no network, game data, or real references."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent


class CloneReferenceTest(unittest.TestCase):
    def test_only_locked_revision_submodules_are_fetched(self):
        for with_submodule in (False, True):
            with self.subTest(with_submodule=with_submodule):
                self.exercise_reference(with_submodule)

    def exercise_reference(self, with_submodule):
        with tempfile.TemporaryDirectory(prefix="bananapad-clone-") as folder:
            root = Path(folder)
            origin = root / "origin"
            origin.mkdir()
            env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1",
                       GIT_CONFIG_GLOBAL=os.devnull, GIT_ALLOW_PROTOCOL="file")

            def git(*args):
                return subprocess.check_output(
                    ["git", "-c", "core.hooksPath=" + os.devnull,
                     "-c", "commit.gpgsign=false", "-c", "user.name=Fixture",
                     "-c", "user.email=fixture@example.invalid", *args],
                    cwd=origin, env=env, stderr=subprocess.STDOUT,
                    text=True, timeout=15).strip()

            git("init", "-q")
            (origin / "source.txt").write_text("synthetic pinned source\n")
            git("add", "source.txt")
            modules = ""
            if with_submodule:
                child = root / "required-origin"
                git("init", "-q", str(child))
                (child / "dependency.txt").write_text("synthetic locked dependency\n")
                git("-C", str(child), "add", "dependency.txt")
                git("-C", str(child), "commit", "-qm", "Required fixture")
                child_pin = git("-C", str(child), "rev-parse", "HEAD")
                modules = '[submodule "required"]\n\tpath = required\n\turl = ' + str(child) + '\n'
                (origin / ".gitmodules").write_text(modules)
                git("add", ".gitmodules")
                git("update-index", "--add", "--cacheinfo", "160000," + child_pin + ",required")
            git("commit", "-qm", "Pinned fixture")
            pin = git("rev-parse", "HEAD")
            # Newer HEAD adds an unavailable dependency absent at the pin.
            missing = root / "unavailable-new-head-dependency"
            (origin / ".gitmodules").write_text(
                modules + '[submodule "unused"]\n\tpath = unused\n\turl = ' + str(missing) + '\n')
            git("add", ".gitmodules")
            git("update-index", "--add", "--cacheinfo", "160000," + pin + ",unused")
            git("commit", "-qm", "Unneeded latest dependency")

            scripts = root / "player" / "scripts"
            (scripts / "lib").mkdir(parents=True)
            (scripts / "lib" / "common.sh").write_bytes(
                (ROOT / "scripts/lib/common.sh").read_bytes())
            ref = os.environ.get("BANANAPAD_CLONE_TEST_REF")
            source = (subprocess.check_output(
                ["git", "show", ref + ":scripts/clone-sources.sh"], cwd=ROOT,
                text=True, timeout=15) if ref else
                (ROOT / "scripts/clone-sources.sh").read_text())
            # Run the actual reference helper, without the five real-repo driver.
            helper = scripts / "clone-reference.sh"
            helper.write_text(source.split('mkdir -p "$BANANAPAD_ROOT/ref"')[0] +
                '\nfixture_url="$1"; fixture_pin="$2"\n'
                'lock_value() { case "$1" in *.url) printf "%s\\n" "$fixture_url";; '
                '*.commit) printf "%s\\n" "$fixture_pin";; *) return 1;; esac; }\n'
                'clone_reference fixture "$3"\n')
            target = root / "player" / "ref" / "fixture"
            target.parent.mkdir()
            result = subprocess.run([
                "/bin/bash", str(helper), str(origin), pin, str(target)],
                env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                timeout=30)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(git("-C", str(target), "rev-parse", "HEAD"), pin)
            self.assertEqual(git("-C", str(target), "status", "--porcelain"), "")
            self.assertEqual(git("-C", str(target), "remote", "get-url", "--push", "origin"),
                             "DISABLED")
            self.assertFalse((target / "unused").exists())
            self.assertNotIn(str(missing), result.stderr)
            if with_submodule:
                self.assertEqual(git("-C", str(target / "required"), "rev-parse", "HEAD"), child_pin)
                self.assertEqual(git("-C", str(target / "required"), "remote", "get-url", "--push", "origin"),
                                 "DISABLED")


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Exercise generation, stale-page cleanup and guarded publishing using local Git."""
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parent.parent
PERL = os.environ.get('PVIM_PERL', 'perl')

def run(*args, cwd=None, ok=True):
    result = subprocess.run(args, cwd=cwd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if ok and result.returncode:
        raise AssertionError(result.stdout)
    return result

class WikiTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = pathlib.Path(self.tmp.name)
    def tearDown(self):
        self.tmp.cleanup()
    def generate(self, out):
        return run(PERL, str(ROOT/'tools/wiki.pl'), '--output', str(out))
    def test_generation_idempotent_and_managed_cleanup(self):
        out = self.base/'pages'
        self.generate(out)
        first = {p.name:p.read_bytes() for p in out.iterdir()}
        self.assertEqual(len([p for p in first if p.endswith('.md')]), 22)
        self.assertNotIn(b'@@', first['Home.md'])
        for name, content in first.items():
            if name.endswith('.md'):
                self.assertNotIn(b'perl pvim', content, name)
        self.assertIn(b'pvim -v', first['Full-Manual.md'])
        self.assertIn(b':%s/hello/world/g', first['Quick-Start.md'])
        self.assertIn(b'--no-splash', first['Full-Manual.md'])
        self.generate(out)
        self.assertEqual(first, {p.name:p.read_bytes() for p in out.iterdir()})
        (out/'Personal.md').write_text('keep this unmanaged page')
        (out/'Old-Generated.md').write_text('obsolete')
        with (out/'.pvim-wiki-manifest').open('a') as f:
            f.write('Old-Generated.md\n')
        self.generate(out)
        self.assertTrue((out/'Personal.md').exists())
        self.assertFalse((out/'Old-Generated.md').exists())
    def test_bad_link_fails_before_output(self):
        source = self.base/'source'
        source.mkdir()
        shutil.copy(ROOT/'pvim', source/'pvim')
        shutil.copy(ROOT/'Changes', source/'Changes')
        shutil.copytree(ROOT/'docs', source/'docs')
        (source/'tools').mkdir()
        shutil.copy(ROOT/'tools/wiki.pl', source/'tools/wiki.pl')
        with (source/'docs/wiki/Home.md').open('a') as f:
            f.write('\n[Broken](No-Such-Page)\n')
        out = self.base/'output'
        result = run(PERL, str(source/'tools/wiki.pl'), '--output', str(out), ok=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Broken wiki link', result.stdout)
        self.assertFalse(out.exists())
    def test_publish_push_noop_and_dirty_guard(self):
        bare = self.base/'remote.git'
        run('git','init','--bare',str(bare))
        wiki = self.base/'wiki'
        run('git','clone',str(bare),str(wiki))
        run('git','checkout','-b','master',cwd=wiki)
        run('git','config','user.name','Test',cwd=wiki)
        run('git','config','user.email','test@example.invalid',cwd=wiki)
        (wiki/'Home.md').write_text('initial')
        run('git','add','Home.md',cwd=wiki)
        run('git','commit','-m','Initialize wiki',cwd=wiki)
        run('git','push','-u','origin','master',cwd=wiki)
        run('sh',str(ROOT/'tools/publish-wiki.sh'),str(wiki))
        first=run('git','rev-parse','HEAD',cwd=wiki).stdout
        self.assertEqual(first,run('git','rev-parse','refs/heads/master',cwd=bare).stdout)
        self.assertTrue((wiki/'Full-Manual.md').exists())
        result=run('sh',str(ROOT/'tools/publish-wiki.sh'),str(wiki))
        self.assertIn('already current',result.stdout)
        self.assertEqual(first,run('git','rev-parse','HEAD',cwd=wiki).stdout)
        (wiki/'Home.md').write_text('uncommitted user edit')
        result=run('sh',str(ROOT/'tools/publish-wiki.sh'),str(wiki),ok=False)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('dirty',result.stdout)
        self.assertEqual((wiki/'Home.md').read_text(),'uncommitted user edit')

if __name__ == '__main__':
    unittest.main(verbosity=2)

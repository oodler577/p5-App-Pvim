#!/usr/bin/env python3
"""Actual OS-pipe stdin tests, including native Windows without a terminal."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = str(Path(__file__).resolve().parent.parent / 'pvim')
PERL = os.environ.get('PVIM_PERL', 'perl')

class PipeTests(unittest.TestCase):
    def test_binary_import_and_filter(self):
        with tempfile.TemporaryDirectory(prefix='pvim pipe ') as d:
            target = Path(d) / 'result with spaces'
            for text in (b'hi\n', b'one\r\ntwo\nlast', b'', b'\x00:q!\n', b'x\r\n' * 50000):
                with self.subTest(size=len(text)):
                    p = subprocess.run([PERL, SCRIPT, '--batch', '-c', 'w! ' + str(target), '-'],
                                       input=text, capture_output=True, timeout=30)
                    self.assertEqual(p.returncode, 0, p.stderr)
                    self.assertEqual(target.read_bytes(), text)
            p = subprocess.run([PERL, SCRIPT, '--batch', '-c', 's/old/new/',
                                '-c', 'w! ' + str(target), '-'],
                               input=b'old\n', capture_output=True, timeout=30)
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(target.read_bytes(), b'new\n')
    def test_quit_guard_and_no_terminal(self):
        for text in (b'', b'hi\n'):
            p = subprocess.run([PERL, SCRIPT, '--batch', '-c', 'q', '-'],
                               input=text, capture_output=True, timeout=10)
            self.assertNotEqual(p.returncode, 0)
            self.assertIn(b'nsaved', p.stderr)
        p = subprocess.run([PERL, SCRIPT], input=b'hi\n', capture_output=True, timeout=10)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn(b'terminal', p.stderr)
        self.assertNotIn(b'\x1b[', p.stdout)

if __name__ == '__main__':
    unittest.main(verbosity=2)

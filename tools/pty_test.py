#!/usr/bin/env python3
"""Real PTY tests: input decoding, file safety, redraw, signals and tty restore."""
import errno
import fcntl
import os
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest

PERL = os.environ.get('PVIM_PERL', 'perl')
SCRIPT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'pvim'))

class Session:
    def __init__(self, *args):
        self.master, self.slave = pty.openpty()
        self.before = termios.tcgetattr(self.slave)
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
        self.proc = subprocess.Popen([PERL, SCRIPT, *args], stdin=self.slave, stdout=self.slave, stderr=self.slave)
        self.output = b''
        self.drain(0.25)
    def drain(self, seconds=0.10):
        until = time.monotonic() + seconds
        while time.monotonic() < until:
            if select.select([self.master], [], [], max(0, until-time.monotonic()))[0]:
                try:
                    chunk = os.read(self.master, 65536)
                    if not chunk:
                        break
                    self.output += chunk
                except OSError as err:
                    if err.errno == errno.EIO:
                        break
                    raise
        return self.output
    def send(self, value):
        os.write(self.master, value)
        self.drain()
    def close(self):
        if self.proc.poll() is None:
            self.proc.terminate()
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            self.proc.wait()
        self.drain(0.01)
        after = termios.tcgetattr(self.slave)
        restored = after == self.before
        if not restored:
            print('TTY DIFF:', [(i, a, b) for i, (a, b) in enumerate(zip(self.before, after)) if a != b], file=sys.stderr)
        os.close(self.master)
        os.close(self.slave)
        return restored

class TerminalTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.tmp.name, 'sample.pl')
        self.s = None
    def tearDown(self):
        if self.s:
            self.assertTrue(self.s.close(), 'terminal attributes restored')
        self.tmp.cleanup()
    def start(self, *args):
        self.s = Session(*args)
        self.assertIsNone(self.s.proc.poll(), self.s.output.decode(errors='replace'))
        return self.s
    def test_splash_and_write(self):
        s = self.start()
        self.assertIn(b'Perl at the prompt', s.output)
        s.send(b' ')
        s.send(b'iuse strict;\rprint "ok";')
        s.send(b'\x1b')
        s.send((':wq ' + self.path + '\r').encode())
        self.assertEqual(s.proc.wait(timeout=5), 0, s.output)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'use strict;\nprint "ok";\n')
    def test_escape_followed_by_commands_and_arrows(self):
        s = self.start('--no-splash', self.path)
        s.send(b'iabc\x1b0x')
        s.send(b'iZ\x1b[DQ')
        s.send(b'\x1b')
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0, s.output)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'QZbc\n')
    def test_bracketed_paste_cannot_quit(self):
        s = self.start('--no-splash', self.path)
        s.send(b'\x1b[200~hello\r:q!\rworld\x1b[201~')
        self.assertIsNone(s.proc.poll())
        s.send(b'\x1b')
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'hello\n:q!\nworld\n')
    def test_paste_from_prompt_is_data(self):
        s = self.start('--no-splash', self.path)
        s.send(b':')
        s.send(b'\x1b[200~q!\rhello\x1b[201~')
        self.assertIsNone(s.proc.poll())
        s.send(b'\x1b')
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'q!\nhello\n')
    def test_escape_open_above(self):
        s = self.start('--no-splash', self.path)
        s.send(b'ione\x1bOzero')
        s.send(b'\x1b')
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'zero\none\n')
    def test_quit_guard_and_resize(self):
        s = self.start('--no-splash', self.path)
        s.send(b'iunsaved')
        s.send(b'\x1b')
        s.send(b':q\r')
        self.assertIn(b'Unsaved changes', s.output)
        fcntl.ioctl(s.slave, termios.TIOCSWINSZ, struct.pack('HHHH', 12, 40, 0, 0))
        s.proc.send_signal(signal.SIGWINCH)
        s.send(b'\x0c')
        s.send(b':q!\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        self.assertFalse(os.path.exists(self.path))
    def test_signal_restores_tty(self):
        s = self.start('--no-splash')
        s.proc.send_signal(signal.SIGTERM)
        self.assertNotEqual(s.proc.wait(timeout=5), 0)
        s.drain()
        self.assertIn(b'Terminated', s.output)
    def test_file_bytes_cannot_control_terminal(self):
        with open(self.path, 'wb') as f:
            f.write(b'\x1b]52;c;evil\x07\n')
        s = self.start(self.path)
        self.assertNotIn(b'\x1b]52', s.output)
        self.assertIn(b'<1B>]52;c;evil<07>', re.sub(rb'\x1b\[[0-9;?]*[A-Za-z]', b'', s.output))
        s.send(b':q\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)

if __name__ == '__main__':
    unittest.main(verbosity=2)

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
        self.proc = subprocess.Popen([PERL, SCRIPT, *args], stdin=self.slave, stdout=self.slave, stderr=self.slave, preexec_fn=os.setpgrp)
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
    def wait_stopped(self):
        until = time.monotonic() + 5
        while time.monotonic() < until:
            pid, status = os.waitpid(self.proc.pid, os.WNOHANG | os.WUNTRACED)
            if pid:
                if os.WIFSTOPPED(status):
                    self.drain()
                    return status
                raise AssertionError('editor exited instead of stopping: ' + repr(status))
            self.drain(0.02)
        raise AssertionError('editor did not enter kernel stopped state')
    def resume(self):
        self.proc.send_signal(signal.SIGCONT)
        self.drain(0.15)
    def close(self):
        if self.proc.poll() is None:
            self.proc.send_signal(signal.SIGCONT)
            self.proc.terminate()
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            self.proc.wait()
        self.drain(0.01)
        after = termios.tcgetattr(self.slave)
        # Darwin sets PENDIN when ICANON is restored, even with identical settings.
        # Kernel state, not a configuration leak: xnu/bsd/kern/tty.c TIOCSETA.
        before = list(self.before)
        if sys.platform == 'darwin':
            pendin = termios.PENDIN
            before[3] &= ~pendin
            after[3] &= ~pendin
        restored = after == before
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
    def test_ctrl_z_preserves_insert_and_unsaved_text(self):
        s = self.start('--no-splash', self.path)
        s.send(b'ifirst')
        s.send(b'\x1a')
        status = s.wait_stopped()
        self.assertEqual(os.WSTOPSIG(status), signal.SIGTSTP)
        self.assertTrue(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        self.assertTrue(termios.tcgetattr(s.slave)[3] & termios.ECHO)
        self.assertIn(b'\x1b[?1049l', s.output)
        self.assertTrue(s.output.endswith(b'\n'))
        s.resume()
        self.assertFalse(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        # A long macOS TMPDIR path may clip the mode label in an 80-column
        # status line. Check the insert-position cursor and actual saved text.
        self.assertIn(b'\x1b[1;6H', s.output)
        s.send(b' second')
        s.send(b'\x1b')
        # Repeated suspend/resume in normal mode must work too.
        s.send(b'\x1a')
        s.wait_stopped()
        s.resume()
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        s.drain()
        self.assertTrue(s.output.endswith(b'\n'))
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'first second\n')
    def test_suspend_from_prompt_and_external_signal(self):
        s = self.start('--no-splash', self.path)
        s.send(b'ihello')
        s.send(b'\x1b')
        s.send(b':w')
        s.send(b'\x1a')
        s.wait_stopped()
        s.resume()
        self.assertIn(b':w', s.output)
        s.send(b'\r')
        s.proc.send_signal(signal.SIGTSTP)
        s.wait_stopped()
        s.resume()
        s.send(b':q\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'hello\n')
    def test_suspend_on_splash(self):
        s = self.start()
        initial = s.output.count(b'Perl at the prompt')
        s.send(b'\x1a')
        s.wait_stopped()
        s.resume()
        self.assertGreater(s.output.count(b'Perl at the prompt'), initial)
        s.send(b' ')
        s.send(b':q\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
    def test_line_numbers_default_off_and_yellow_three_columns(self):
        with open(self.path, 'wb') as f:
            f.write(b'alpha\nbeta\n')
        s = self.start('--no-syntax', self.path)
        self.assertIn(b'\x1b[1;1H\x1b[0malpha', s.output)
        self.assertNotIn(b'\x1b[33m', s.output)
        s.send(b':set number\r')
        self.assertIn(b'\x1b[33m  1\x1b[0m alpha', s.output)
        self.assertIn(b'\x1b[33m  2\x1b[0m beta', s.output)
        self.assertIn(b'\x1b[1;5H', s.output)
        before = len(s.output)
        s.send(b':set nonumber\r')
        self.assertIn(b'\x1b[1;1H\x1b[0malpha', s.output[before:])
        s.send(b':q\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
    def test_number_field_grows_without_truncation(self):
        with open(self.path, 'wb') as f:
            f.write(b'x\n' * 1000)
        s = self.start('--no-syntax', self.path)
        s.send(b':set nu\r')
        self.assertIn(b'\x1b[33m   1\x1b[0m x', s.output)
        s.send(b'G')
        self.assertIn(b'\x1b[33m1000\x1b[0m x', s.output)
        s.send(b':q\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
    def test_tty_eof_exits_with_newline(self):
        s = self.start('--no-splash')
        # VMIN=0 allows a real zero-byte tty read (EOF) without disconnecting
        # the PTY master, so the final terminal output can still be observed.
        attrs = termios.tcgetattr(s.slave)
        attrs[6][termios.VMIN] = 0
        attrs[6][termios.VTIME] = 1
        termios.tcsetattr(s.slave, termios.TCSANOW, attrs)
        s.proc.send_signal(signal.SIGWINCH)
        self.assertEqual(s.proc.wait(timeout=5), 0)
        s.drain()
        self.assertTrue(s.output.endswith(b'\n'))
    def test_shell_filter_restores_ui_and_undo(self):
        with open(self.path, 'wb') as f:
            f.write(b'one\ntwo\nthree\n')
        s = self.start(self.path)
        s.send(b':2! tr a-z A-Z\r')
        self.assertIn(b'Filtered 1 lines', s.output)
        self.assertFalse(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        s.send(b'u')
        s.send(b':%! tr a-z A-Z\r')
        self.assertIn(b'Filtered 3 lines', s.output)
        s.send(b":.! sh -c 'echo discarded; echo diagnostic >&2; exit 7'\r")
        self.assertIn(b'Filter failed (exit 7)', s.output)
        self.assertFalse(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        s.drain()
        self.assertTrue(s.output.endswith(b'\n'))
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'ONE\nTWO\nTHREE\n')
    def test_shell_display_and_read_follow_vim(self):
        with open(self.path, 'wb') as f:
            f.write(b'original\n')
        s = self.start(self.path)
        s.send(b':! printf "visible-output"\r')
        self.assertIn(b'visible-output', s.output)
        self.assertIn(b'Press ENTER', s.output)
        self.assertTrue(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        s.send(b'\r')
        self.assertFalse(termios.tcgetattr(s.slave)[3] & termios.ICANON)
        s.send(b':r ! printf "inserted\\n"\r')
        s.send(b'!!tr a-z A-Z\r')
        s.send(b':wq\r')
        self.assertEqual(s.proc.wait(timeout=5), 0)
        with open(self.path, 'rb') as f:
            self.assertEqual(f.read(), b'original\nINSERTED\n')
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
        s.send(b'\x1b[200~hello\x1a\r:q!\rworld\x1b[201~')
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
        self.assertTrue(s.output.endswith(b'\n'))
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

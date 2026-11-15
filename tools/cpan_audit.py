#!/usr/bin/env python3
"""Audit a built App::Pvim kit; needs Python only on the author/CI machine."""
import json
from pathlib import Path
import re
import subprocess
import sys

root = Path(sys.argv[1])
manifest = [line.strip() for line in (root / 'MANIFEST').read_text().splitlines()
            if line.strip() and not line.lstrip().startswith('#')]
allowed = re.compile(r'^(?:pvim|README\.md|Changes|LICENSE|ARTISTIC|COPYING|dist\.ini|Makefile\.PL|META\.(?:json|yml)|MANIFEST|script/pvim|lib/App/Pvim\.pm|inc/Pvim/Build\.pm|t/[^/]+\.t|tools/[^/]+\.(?:pl|py|sh)|docs/(?:wiki/)?[^/]+\.md)$')
for entry in manifest:
    assert allowed.fullmatch(entry), 'Unexpected archive member: ' + entry
    assert not re.search(r'(?:__pycache__|\.bak$|\.tdy$|\.log$|~$)', entry), entry
    assert (root / entry).is_file(), 'Missing manifest member: ' + entry
actual = {str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()}
# Run this on a freshly built kit, before MakeMaker creates consumer artifacts.
assert actual == set(manifest), 'Unmanifested/missing files: ' + repr(actual ^ set(manifest))
meta = json.loads((root / 'META.json').read_text())
assert meta['name'] == 'App-Pvim'
assert meta['license'] == ['perl_5']
assert 'App::Pvim' not in meta.get('no_index', {}).get('package', [])
requires = meta['prereqs']['runtime']['requires']
assert requires['perl'] in ('5.010', '5.010000', '5.01'), requires
expected = {'perl', 'Digest::SHA', 'Errno', 'File::Basename', 'File::Spec',
            'File::Temp', 'Getopt::Long', 'IO::Select', 'Pod::Usage', 'POSIX'}
assert set(requires) == expected, requires
assert set(meta['prereqs'].get('configure', {}).get('requires', {})) <= {'ExtUtils::MakeMaker'}, meta['prereqs']
for file in ('pvim', 'script/pvim', 'lib/App/Pvim.pm'):
    subprocess.run(['perl', '-MPod::Checker', '-e',
                    'exit(Pod::Checker::podchecker($ARGV[0]) > 0 ? 1 : 0)',
                    str(root / file)], check=True)
assert (root / 'pvim').read_bytes() == (root / 'script/pvim').read_bytes()
print('CPAN audit passed: manifest allowlist, complete kit, core runtime prerequisites, license, POD and identical script')

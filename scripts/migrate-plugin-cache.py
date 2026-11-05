"""Explicit offline migration of reviewed Git checkouts; source cache is read-only."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
parser.add_argument('--target', type=Path, required=True)
parser.add_argument('--lockfile', type=Path, required=True)
args = parser.parse_args()
lock = json.loads(args.lockfile.read_text())
assert lock['version'] == 1
for name, entry in lock['plugins'].items():
    source, target = args.source / name, args.target / name
    if not (source / '.git').is_dir():
        continue
    head = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    if head != entry['commit']:
        present = subprocess.run(['git', '-C', str(source), 'cat-file', '-e', entry['commit'] + '^{commit}'], capture_output=True)
        if present.returncode:
            raise SystemExit(f'{name}: locked revision is not cached; install it explicitly')
    if target.exists():
        marker = target / '.git/plugin-tools-owner.json'
        if not marker.exists() or json.loads(marker.read_text()).get('source') != entry['source'] or json.loads(marker.read_text()).get('id') != name:
            raise SystemExit(f'{target}: target exists without matching ownership')
        current = subprocess.check_output(['git', '-C', str(target), 'rev-parse', 'HEAD'], text=True).strip()
        if current != entry['commit']:
            raise SystemExit(f'{target}: existing checkout differs from reviewed lock')
        print(f'exists {name}')
        continue
    args.target.mkdir(parents=True, exist_ok=True)
    # copytree preserves ignored build artifacts. macOS copy2 uses copyfile;
    # the old cache is retained intact for switching back to the old branch.
    shutil.copytree(source, target, symlinks=True)
    (target / '.git/plugin-tools-owner.json').write_text(json.dumps({'id': name, **entry}) + '\n')
    with (target / '.git/info/exclude').open('a') as file:
        file.write('\n/doc/tags\n/doc/tags-*\n')
    if head != entry['commit']:
        subprocess.run(['git', '-C', str(target), 'checkout', '--quiet', '--detach', entry['commit']], check=True)
    print(f'migrated {name}')

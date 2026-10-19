#!/usr/bin/env python3
"""Install the user-approved local repair with original app + data backups."""
from pathlib import Path
from datetime import datetime
import argparse
import hashlib
import os
import plistlib
import shutil
import signal
import sqlite3
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument('--expected-sha256', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
app = Path('/Applications/Pastel it！.app')
staged = Path((root / 'work/staged-app-path.txt').read_text().strip())
binary = app / 'Contents/MacOS/PasteIt'
assert hashlib.sha256(binary.read_bytes()).hexdigest() == args.expected_sha256, 'Installed app changed; abort'
assert plistlib.loads((staged / 'Contents/Info.plist').read_bytes())['CFBundleIdentifier'] == 'app.paste-it.mac'
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(staged)], check=True)
backup = root / 'work/backups' / datetime.now().strftime('%Y%m%d-%H%M%S')
backup.mkdir(parents=True)
# Stop only the installed executable, after verifying its hash. UI automation
# cannot connect to the current menu-bar-only instance; SIGTERM is scoped here.
def installed_pids():
    output = subprocess.check_output(['ps', '-axo', 'pid=,comm='], text=True)
    return [int(line.strip().split(None, 1)[0]) for line in output.splitlines()
            if line.strip().split(None, 1)[-1] == str(binary)]
for pid in installed_pids():
    os.kill(pid, signal.SIGTERM)
for _ in range(50):
    if not installed_pids(): break
    time.sleep(0.1)
assert not installed_pids(), 'App still running; abort without replacing'
data = Path.home() / 'Library/Application Support/PasteIt'
if data.exists():
    shutil.copytree(data, backup / 'PasteIt-data', symlinks=True)
prefs = Path.home() / 'Library/Preferences/app.paste-it.mac.plist'
if prefs.exists(): shutil.copy2(prefs, backup / prefs.name)
previous = backup / 'Paste It.previous-install-backup'
shutil.move(str(app), previous)
try:
    shutil.move(str(staged), app)
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
except BaseException:
    if app.exists(): shutil.move(str(app), backup / 'Paste It.failed-install-backup')
    shutil.move(str(previous), app)
    raise
print(f'Installed: {app}\nBackup: {backup}')
print('Executable SHA256:', hashlib.sha256(binary.read_bytes()).hexdigest())

#!/usr/bin/env python3
"""Build output -> explicitly approved, ad-hoc signed local repair (no release)."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
products = root / '.build/release'
assert (products / 'PasteIt').is_file(), 'Run swift build -c release first'
assert (products / 'PasteIt_PasteIt.bundle').is_dir(), 'Missing translations'
framework = root / 'work/dependencies/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework'
assert framework.is_dir(), 'Missing Sparkle framework'
# Documents metadata services can add FinderInfo after signing. Assemble/sign in
# a temporary directory, then archive the verified result into this project.
app = Path(tempfile.mkdtemp(prefix='pasteit-local-settings-')) / 'Pastel it！.app'
for directory in ['MacOS', 'Resources', 'Frameworks']:
    (app / 'Contents' / directory).mkdir(parents=True, exist_ok=True)
shutil.copyfile(products / 'PasteIt', app / 'Contents/MacOS/PasteIt')
(app / 'Contents/MacOS/PasteIt').chmod(0o755)
for name in ['AppIcon.icns', 'Assets.car']:
    if (root / 'Resources' / name).is_file():
        shutil.copyfile(root / 'Resources' / name, app / 'Contents/Resources' / name)
for bundle in products.glob('*.bundle'):
    shutil.copytree(bundle, app / 'Contents/Resources' / bundle.name, symlinks=True)
shutil.copytree(framework, app / 'Contents/Frameworks/Sparkle.framework', symlinks=True)
with (root / 'Info.plist').open('rb') as f:
    info = plistlib.load(f)
info['PasteItLocalRepair'] = '2026-10-19: launch resources, modern Vision OCR, settings icons/resizing, permission restart notice, configurable and clearable global shortcuts'
with (app / 'Contents/Info.plist').open('wb') as f:
    plistlib.dump(info, f, sort_keys=False)
subprocess.run(['install_name_tool', '-add_rpath', '@executable_path/../Frameworks', str(app / 'Contents/MacOS/PasteIt')], check=True)
for name in ['com.apple.FinderInfo', 'com.apple.ResourceFork']:
    subprocess.run(['xattr', '-r', '-d', name, str(app)], capture_output=True)
subprocess.run(['codesign', '--force', '--deep', '--sign', '-', str(app)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', '--verbose=2', str(app)], check=True)
dist = root / 'dist'
dist.mkdir(exist_ok=True)
archive = dist / 'Pastel-it-local-repair.zip'
subprocess.run(['ditto', '--norsrc', '--noextattr', '-c', '-k', '--keepParent', str(app), str(archive)], check=True)
(root / 'work/staged-app-path.txt').write_text(str(app))
print(f'Staged: {app}\nArchive: {archive}')

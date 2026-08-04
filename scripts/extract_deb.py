import lzma
import tarfile
import glob
import os
import shutil
import sys

deb = sys.argv[1]
out = sys.argv[2]
extract = os.path.join(out, 'extract')
os.makedirs(extract, exist_ok=True)

with tarfile.open(deb, 'r:') as d:
    d.extractall(extract)

for f in glob.glob(os.path.join(extract, 'data.tar.*')):
    mode = 'r:lzma' if f.endswith('.lzma') else 'r:'
    with tarfile.open(f, mode) as t:
        t.extractall(extract)

dylib = glob.glob(os.path.join(extract, 'Library/MobileSubstrate/DynamicLibraries/*.dylib'))
plist = glob.glob(os.path.join(extract, 'Library/MobileSubstrate/DynamicLibraries/*.plist'))
if not dylib or not plist:
    print('ERROR: no dylib/plist found in deb')
    sys.exit(1)

shutil.copy(dylib[0], os.path.join(out, 'ForceATV.dylib'))
shutil.copy(plist[0], os.path.join(out, 'ForceATV.plist'))
print('extracted:', dylib[0], '->', os.path.join(out, 'ForceATV.dylib'))

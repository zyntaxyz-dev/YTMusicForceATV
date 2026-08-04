import lzma
import tarfile
import glob
import os
import shutil
import sys


def ar_extract(path, destdir):
    """Minimal ar (System V) archive extractor. Returns list of (name, data)."""
    with open(path, 'rb') as f:
        magic = f.read(8)
        if magic != b'!<arch>\n':
            raise ValueError('not an ar archive')
        while True:
            hdr = f.read(60)
            if len(hdr) < 60:
                break
            name = hdr[0:16].decode('latin1').strip()
            size = int(hdr[48:58].decode('latin1').strip() or '0')
            data = f.read(size)
            if size % 2 == 1:
                f.read(1)  # padding
            if name.endswith('/'):
                continue  # symbol table / name table
            with open(os.path.join(destdir, name), 'wb') as of:
                of.write(data)


deb = sys.argv[1]
out = sys.argv[2]
extract = os.path.join(out, 'extract')
os.makedirs(extract, exist_ok=True)

ar_extract(os.path.abspath(deb), extract)

data = glob.glob(os.path.join(extract, 'data.tar.*'))
if not data:
    print('ERROR: no data.tar.* inside deb')
    sys.exit(1)

mode = 'r:lzma' if data[0].endswith('.lzma') else 'r:'
if data[0].endswith('.lzma'):
    with tarfile.open(fileobj=lzma.open(data[0], 'rb'), mode='r:') as t:
        t.extractall(extract)
else:
    with tarfile.open(data[0], mode) as t:
        t.extractall(extract)

dylib = glob.glob(os.path.join(extract, 'Library/MobileSubstrate/DynamicLibraries/*.dylib'))
plist = glob.glob(os.path.join(extract, 'Library/MobileSubstrate/DynamicLibraries/*.plist'))
if not dylib or not plist:
    print('ERROR: no dylib/plist found in deb')
    sys.exit(1)

shutil.copy(dylib[0], os.path.join(out, 'ForceATV.dylib'))
shutil.copy(plist[0], os.path.join(out, 'ForceATV.plist'))
print('extracted:', dylib[0], '->', os.path.join(out, 'ForceATV.dylib'))

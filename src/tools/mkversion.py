"""Write build/version.inc from the VERSION file at the repository root.

    py -3 mkversion.py <VERSION file> <output .inc>

The driver's start-up banner prints "v" + this text. The text must be 4 characters (like 1.1b), so the banner keeps its length
and the memory map does not move.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
ver = open(src, encoding='ascii').read().strip()
if len(ver) != 4 or not all(32 < ord(c) < 127 and c != '"' for c in ver):
    sys.exit('VERSION must be 4 printable characters, like 1.1b (got %r)' % ver)
open(out, 'w', encoding='ascii', newline='\n').write(
    '; made by tools/mkversion.py from the VERSION file: do not edit\n.define VERSION_TXT "%s"\n' % ver)
print('version', ver)

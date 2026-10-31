import sys
from PIL import Image
d = open(sys.argv[1], 'rb').read()
im = Image.new('L', (280, 192), 0)
px = im.load()
for y in range(192):
    base = (y % 8) * 0x400 + ((y // 8) % 8) * 0x80 + (y // 64) * 0x28
    for bx in range(40):
        b = d[base + bx]
        for k in range(7):
            if b >> k & 1:
                px[bx * 7 + k, y] = 255
im.resize((280 * 3, 192 * 3), Image.NEAREST).save(sys.argv[2])

"""Generate resources/drawables/launcher_icon.png (60x60 RGBA) using only the stdlib."""
import struct
import sys
import zlib

W = H = 60


def px(x, y):
    cx = cy = 29.5
    if (x - cx) ** 2 + (y - cy) ** 2 > 29.5 ** 2:
        return (0, 0, 0, 0)
    if 16 <= x <= 43 and 14 <= y <= 40:          # bus body
        if 19 <= x <= 40 and 17 <= y <= 27:      # windscreen
            return (0, 70, 140, 255)
        return (255, 255, 255, 255)
    if (20 <= x <= 25 or 34 <= x <= 39) and 41 <= y <= 45:  # wheels
        return (255, 255, 255, 255)
    return (0, 70, 140, 255)


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


raw = b"".join(b"\x00" + bytes(c for x in range(W) for c in px(x, y)) for y in range(H))
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(raw))
       + chunk(b"IEND", b""))
with open(sys.argv[1], "wb") as f:
    f.write(png)

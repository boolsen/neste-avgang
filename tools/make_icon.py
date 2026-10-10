"""Draw the bus icon: python3 -I tools/make_icon.py <size_px> <out.png>  (stdlib only, RGBA)."""
import struct
import sys
import zlib

SS = 8
BLUE = (0x0E, 0x4C, 0x92)
WHITE = (255, 255, 255)
AMBER = (0xFF, 0xB3, 0x00)


def rrect(x0, y0, x1, y1, r, col):
    def hit(x, y):
        if not (x0 <= x <= x1 and y0 <= y <= y1):
            return False
        dx = max(x0 + r - x, x - (x1 - r), 0)
        dy = max(y0 + r - y, y - (y1 - r), 0)
        return dx * dx + dy * dy <= r * r
    return hit, col


def circle(cx, cy, r, col):
    return (lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r), col


SHAPES = [
    circle(0.5, 0.5, 0.5, BLUE),
    rrect(0.27, 0.20, 0.73, 0.74, 0.08, WHITE),
    rrect(0.32, 0.27, 0.68, 0.50, 0.03, BLUE),
    rrect(0.36, 0.225, 0.64, 0.255, 0, AMBER),
    circle(0.36, 0.64, 0.035, AMBER),
    circle(0.64, 0.64, 0.035, AMBER),
    rrect(0.31, 0.72, 0.39, 0.80, 0.02, WHITE),
    rrect(0.61, 0.72, 0.69, 0.80, 0.02, WHITE),
]


def sample(x, y):
    col = None
    for hit, c in SHAPES:
        if hit(x, y):
            col = c
    return col


def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def render(n):
    rows = []
    for j in range(n):
        row = bytearray([0])
        for i in range(n):
            r = g = b = cnt = 0
            for sj in range(SS):
                for si in range(SS):
                    c = sample((i + (si + 0.5) / SS) / n, (j + (sj + 0.5) / SS) / n)
                    if c:
                        r += c[0]; g += c[1]; b += c[2]; cnt += 1
            if cnt:
                row += bytes((r // cnt, g // cnt, b // cnt, cnt * 255 // (SS * SS)))
            else:
                row += bytes(4)
        rows.append(bytes(row))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", n, n, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"".join(rows)))
            + chunk(b"IEND", b""))


if __name__ == "__main__":
    with open(sys.argv[2], "wb") as f:
        f.write(render(int(sys.argv[1])))

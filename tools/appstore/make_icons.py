"""Square framed App Store icons from the Moore Design logo (mooredesign.net/images/MD-Logo2021.png)."""
import os, sys
from PIL import Image, ImageDraw
here = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
logo = Image.open(os.path.join(here, "branding", "MD-Logo2021.png")).convert("RGBA")
S = 1024
base = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(base)
d.rounded_rectangle([8, 8, S - 9, S - 9], radius=150, fill=(255, 255, 255, 255), outline=(51, 51, 51, 255), width=28)
pad = 170
lw = S - 2 * pad
l = logo.copy(); l.thumbnail((lw, lw), Image.LANCZOS)
base.alpha_composite(l, ((S - l.width) // 2, (S - l.height) // 2))
for n in (512, 200, 120, 64, 32, 16):
    base.resize((n, n), Image.LANCZOS).save(os.path.join(out, f"MED2026-icon-{n}.png"))
base.resize((256, 256), Image.LANCZOS).save(os.path.join(out, "MED2026.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (256, 256)])

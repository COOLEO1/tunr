from PIL import Image, ImageDraw
import os
os.makedirs('assets', exist_ok=True)
S = 1024
INK = (18, 18, 18)

def glyph(d, k):
    t = lambda x, y: (512 + (x - 512) * k, 512 + (y - 512) * k)
    d.ellipse([t(270, 600), t(530, 800)], fill=INK)
    d.rectangle([t(500, 250), t(545, 700)], fill=INK)
    d.polygon([t(545, 250), t(770, 340), t(770, 470), t(545, 380)], fill=INK)

bg = Image.new('RGB', (S, S))
px = ImageDraw.Draw(bg)
for y in range(S):
    f = y / S
    px.line([(0, y), (S, y)], fill=(int(40 - 14 * f), int(215 - 60 * f), int(100 - 30 * f)))
glyph(px, 0.9)
bg.save('assets/icon.png')

fg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
glyph(ImageDraw.Draw(fg), 0.7)
fg.save('assets/icon_fg.png')

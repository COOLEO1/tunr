from PIL import Image, ImageDraw
import os
os.makedirs('assets', exist_ok=True)
S = 1024

def glyph(d, k):
    t = lambda x, y: (512 + (x - 512) * k, 512 + (y - 512) * k)
    d.ellipse([t(270, 600), t(530, 800)], fill='white')
    d.rectangle([t(500, 250), t(545, 700)], fill='white')
    d.polygon([t(545, 250), t(770, 340), t(770, 470), t(545, 380)], fill='white')

bg = Image.new('RGB', (S, S))
px = ImageDraw.Draw(bg)
for y in range(S):
    f = y / S
    px.line([(0, y), (S, y)], fill=(int(139 - 94 * f), int(92 - 72 * f), int(246 - 126 * f)))
glyph(px, 0.9)
bg.save('assets/icon.png')

fg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
glyph(ImageDraw.Draw(fg), 0.7)
fg.save('assets/icon_fg.png')

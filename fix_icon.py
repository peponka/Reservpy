from PIL import Image
import numpy as np
from collections import deque

src = r"C:\Users\pepeq\OneDrive\Desktop\Reservpy\reservpy Icono.png"
out = r"C:\Users\pepeq\OneDrive\Desktop\Reservpy\assets\images\icon.png"

img = Image.open(src).convert("RGBA")
data = np.array(img, dtype=np.uint8)
h, w = data.shape[:2]
print(f"Tamaño: {w}x{h}")

# 1. Pintar zona del texto (y=980..1100) con el verde del fondo
bg = (33, 164, 130, 255)
data[980:1100, :] = bg

# 2. Flood-fill desde las 4 esquinas: blanco -> transparente
def flood_fill(data, sx, sy):
    H, W = data.shape[:2]
    q = deque([(sx, sy)])
    vis = set()
    while q:
        x, y = q.popleft()
        if x < 0 or x >= W or y < 0 or y >= H:
            continue
        if (x, y) in vis:
            continue
        vis.add((x, y))
        r, g, b, a = data[y, x]
        if r > 200 and g > 200 and b > 200:
            data[y, x] = (0, 0, 0, 0)
            q.append((x+1, y))
            q.append((x-1, y))
            q.append((x, y+1))
            q.append((x, y-1))

print("Flood-fill esquinas...")
flood_fill(data, 0, 0)
flood_fill(data, w-1, 0)
flood_fill(data, 0, h-1)
flood_fill(data, w-1, h-1)

# 3. Escalar a 1024x1024 y guardar
result = Image.fromarray(data, "RGBA").resize((1024, 1024), Image.LANCZOS)
result.save(out, "PNG")

arr = np.array(result)
print(f"Esquina (5,5):     A={arr[5,5,3]}   <- debe ser 0")
print(f"Centro  (512,512): A={arr[512,512,3]} <- debe ser 255")
print(f"Guardado: {out}")

from PIL import Image, ImageDraw
import numpy as np

src = r"C:\Users\pepeq\OneDrive\Desktop\Reservpy\assets\images\icon.png"
web = r"C:\Users\pepeq\OneDrive\Desktop\Reservpy\web"

# Cargar icon.png (ya tiene esquinas transparentes y la R verde)
icon = Image.open(src).convert("RGBA")
BG = (32, 164, 130, 255)  # #20A482

def make_solid(size):
    """Ícono con fondo verde sólido, escalado al tamaño dado."""
    canvas = Image.new("RGBA", (size, size), BG)
    resized = icon.resize((size, size), Image.LANCZOS)
    canvas.paste(resized, (0, 0), resized)
    return canvas

def make_maskable(size):
    """Maskable: fondo sólido verde, ícono centrado en el 80% del área (safe zone)."""
    canvas = Image.new("RGBA", (size, size), BG)
    inner = int(size * 0.72)  # un poco de padding alrededor
    offset = (size - inner) // 2
    resized = icon.resize((inner, inner), Image.LANCZOS)
    canvas.paste(resized, (offset, offset), resized)
    return canvas

# favicon.png — 32x32 sólido
fav = make_solid(32)
fav.save(f"{web}/favicon.png", "PNG")
print("favicon.png OK (32x32)")

# Icon-192.png
make_solid(192).save(f"{web}/icons/Icon-192.png", "PNG")
print("Icon-192.png OK")

# Icon-512.png
make_solid(512).save(f"{web}/icons/Icon-512.png", "PNG")
print("Icon-512.png OK")

# Icon-maskable-192.png
make_maskable(192).save(f"{web}/icons/Icon-maskable-192.png", "PNG")
print("Icon-maskable-192.png OK")

# Icon-maskable-512.png
make_maskable(512).save(f"{web}/icons/Icon-maskable-512.png", "PNG")
print("Icon-maskable-512.png OK")

print("\nTodos los íconos web generados!")

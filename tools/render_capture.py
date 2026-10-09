#!/usr/bin/env python3
"""Transforme la sortie de tests/capture.s en GIF anime et en capture PNG.

Utilisation :
    java -jar rars.jar nc tests/capture.s > capture.txt
    python3 tools/render_capture.py capture.txt --gif docs/demo.gif --png docs/screenshot.png

Chaque ligne commencant par "#F" contient une frame : les couleurs des units de la grille,
ligne par ligne, au format "0x00RRGGBB" (10 caracteres par unit). Les autres lignes (score,
messages de fin) sont ignorees.

Dependance : Pillow (pip install pillow).
"""

import argparse
import math
import sys

from PIL import Image

HEX_WIDTH = len("0x00000000")


def parse_frames(path):
    """Renvoie la liste des frames, chacune etant une liste de couleurs (r, g, b)."""
    frames = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if not line.startswith("#F"):
                continue
            data = line[2:].strip()
            colors = []
            for i in range(0, len(data) - HEX_WIDTH + 1, HEX_WIDTH):
                value = int(data[i : i + HEX_WIDTH], 16)
                colors.append(((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF))
            if colors:
                frames.append(colors)
    return frames


def frame_to_image(colors, unit, gap):
    """Dessine une frame : chaque unit devient un carre de 'unit' pixels separe par 'gap' pixels."""
    side = math.isqrt(len(colors))
    if side * side != len(colors):
        raise ValueError(f"La frame contient {len(colors)} units, ce n'est pas une grille carree.")
    size = side * unit
    image = Image.new("RGB", (size, size), (10, 10, 18))
    pixels = image.load()
    for index, color in enumerate(colors):
        if color == (0, 0, 0):
            continue
        x0, y0 = (index % side) * unit, (index // side) * unit
        for y in range(y0, y0 + unit - gap):
            for x in range(x0, x0 + unit - gap):
                pixels[x, y] = color
    return image


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("capture", help="Fichier texte produit par tests/capture.s")
    parser.add_argument("--gif", help="Chemin du GIF anime a produire")
    parser.add_argument("--png", help="Chemin d'une capture PNG a produire")
    parser.add_argument("--png-frame", type=int, default=None, help="Frame a utiliser pour le PNG (defaut : un tiers de la partie)")
    parser.add_argument("--unit", type=int, default=10, help="Taille d'un unit en pixels (defaut : 10)")
    parser.add_argument("--gap", type=int, default=1, help="Espace entre les units en pixels (defaut : 1)")
    parser.add_argument("--step", type=int, default=2, help="Ne garde qu'une frame sur 'step' dans le GIF (defaut : 2)")
    parser.add_argument("--delay", type=int, default=40, help="Duree d'une frame du jeu en ms (defaut : 40)")
    args = parser.parse_args()

    frames = parse_frames(args.capture)
    if not frames:
        sys.exit("Aucune frame trouvee : le fichier provient-il bien de tests/capture.s ?")
    print(f"{len(frames)} frames lues.")

    if args.png:
        index = args.png_frame if args.png_frame is not None else len(frames) // 3
        frame_to_image(frames[index], args.unit, args.gap).save(args.png)
        print(f"Capture ecrite dans {args.png} (frame {index}).")

    if args.gif:
        selected = frames[:: args.step]
        if selected[-1] is not frames[-1]:
            selected.append(frames[-1])
        images = [frame_to_image(colors, args.unit, args.gap) for colors in selected]
        durations = [args.delay * args.step] * len(images)
        durations[-1] = 2500  # La derniere image (cadre de fin) reste affichee plus longtemps
        images[0].save(args.gif, save_all=True, append_images=images[1:], duration=durations, loop=0, optimize=True)
        print(f"Animation ecrite dans {args.gif} ({len(images)} images).")


if __name__ == "__main__":
    main()

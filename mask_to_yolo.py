"""
mask_to_yolo.py  (v5 - lida com oclusao que parte o objeto em varios pedacos)
Le os screenshots do Unreal (pares RGB + mascara) e gera as labels YOLO.

NOVIDADE v5: quando o objeto esta partido em varios pedacos pela oclusao
(ex: sapatilha cortada ao meio pelo poste), a bounding box engloba TODOS
os pedacos, nao apenas o maior. Pequenos pontos de ruido isolado sao
descartados (componentes abaixo de MIN_COMPONENT pixels).

Processa UM cenario de cada vez (com prefixo no nome).

COMO USAR:
  1. Ajusta SCENARIO_DIR e PREFIXO em baixo
  2. python mask_to_yolo.py
  3. Muda para o outro cenario e corre outra vez

Requisitos: pip install pillow numpy scipy
"""

import os
import glob
import shutil
import numpy as np
from PIL import Image

try:
    from scipy import ndimage
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

# ===================== AJUSTA AQUI =====================
SCENARIO_DIR = "c:/Temp/img"
PREFIXO      = "natureza"      # muda para "natureza" na 2a corrida

OUTPUT_DIR = "./Datasets/Original/Outside_1"
CLASS_ID = 0
# =======================================================

# --- Parametros de cor da mascara (laranja do Unreal) ---
R_MIN, G_MAX, B_MAX = 200, 140, 90
RG_DIFF, RB_DIFF = 80, 140

# Area TOTAL minima de laranja para considerar que ha sapatilha.
# Abaixo disto -> hard negative (label vazia).
MIN_PIXELS = 300

# Tamanho minimo de um componente para CONTAR para a bounding box.
# Componentes mais pequenos que isto sao considerados ruido e ignorados.
# (mas varios componentes validos sao TODOS englobados na mesma caixa)
MIN_COMPONENT = 80
# --------------------------------------------------------

OUT_IMAGES = os.path.join(OUTPUT_DIR, "images")
OUT_LABELS = os.path.join(OUTPUT_DIR, "labels")


def orange_mask(arr):
    r = arr[:, :, 0].astype(int)
    g = arr[:, :, 1].astype(int)
    b = arr[:, :, 2].astype(int)
    return ((r >= R_MIN) & (g <= G_MAX) & (b <= B_MAX) &
            ((r - g) >= RG_DIFF) & ((r - b) >= RB_DIFF))


def bbox_from_arr(arr):
    m = orange_mask(arr)
    total = m.sum()
    if total < MIN_PIXELS:
        return None

    if HAS_SCIPY:
        # Remove componentes pequenos (ruido), mas MANTEM todos os
        # componentes validos (a sapatilha pode estar partida pelo poste).
        labeled, n = ndimage.label(m)
        if n >= 1:
            keep = np.zeros_like(m)
            for comp_id in range(1, n + 1):
                comp = (labeled == comp_id)
                if comp.sum() >= MIN_COMPONENT:
                    keep |= comp
            m = keep
        if m.sum() < MIN_PIXELS:
            return None

    ys, xs = np.where(m)
    if len(xs) == 0:
        return None
    # A caixa engloba TODOS os pedacos validos (do extremo esquerdo
    # ao direito, do topo a base) -> cobre a sapatilha mesmo partida.
    return (int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max()))


def to_yolo(bbox, w, h):
    x1, y1, x2, y2 = bbox
    return ((x1 + x2) / 2 / w, (y1 + y2) / 2 / h,
            (x2 - x1) / w, (y2 - y1) / h)


def main():
    if not HAS_SCIPY:
        print("[aviso] scipy nao instalado - deteccao de ruido limitada.")
        print("        pip install scipy\n")

    os.makedirs(OUT_IMAGES, exist_ok=True)
    os.makedirs(OUT_LABELS, exist_ok=True)

    if not os.path.isdir(SCENARIO_DIR):
        print(f"[!] Pasta nao encontrada: {SCENARIO_DIR}")
        return

    files = sorted(glob.glob(os.path.join(SCENARIO_DIR, "*.png")))
    if not files:
        print(f"[!] Nenhum .png em {SCENARIO_DIR}")
        return

    print(f"[i] Cenario: '{PREFIXO}'  |  {len(files)} ficheiros")
    if len(files) % 2 != 0:
        print("[AVISO] Numero impar de ficheiros - o ultimo fica sem par!\n")

    existentes = glob.glob(os.path.join(OUT_IMAGES, f"{PREFIXO}_*.png"))
    start = len(existentes)

    pair = saved = negs = 0
    for i in range(0, len(files) - 1, 2):
        a = np.array(Image.open(files[i]).convert("RGB"))
        b = np.array(Image.open(files[i + 1]).convert("RGB"))

        if orange_mask(a).sum() >= orange_mask(b).sum():
            mask_arr, rgb_path = a, files[i + 1]
        else:
            mask_arr, rgb_path = b, files[i]

        h, w = mask_arr.shape[:2]
        bbox = bbox_from_arr(mask_arr)

        pair += 1
        base = f"{PREFIXO}_{start + pair:04d}"
        shutil.copy(rgb_path, os.path.join(OUT_IMAGES, base + ".png"))
        lbl = os.path.join(OUT_LABELS, base + ".txt")

        if bbox is None:
            open(lbl, "w").close()
            negs += 1
            continue

        xc, yc, bw, bh = to_yolo(bbox, w, h)
        with open(lbl, "w") as f:
            f.write(f"{CLASS_ID} {xc:.6f} {yc:.6f} {bw:.6f} {bh:.6f}\n")
        saved += 1

    print(f"\n  Pares processados : {pair}")
    print(f"  Com sapatilha     : {saved}")
    print(f"  Hard negatives    : {negs}")
    print(f"  Adicionados como  : {PREFIXO}_{start+1:04d} ... {PREFIXO}_{start+pair:04d}")
    print(f"  Imagens -> {OUT_IMAGES}")
    print(f"  Labels  -> {OUT_LABELS}")
    print("\n  Valida com: python validar.py")


if __name__ == "__main__":
    main()
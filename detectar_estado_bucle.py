import cv2
import numpy as np
import subprocess
import sys
import os

device_id = sys.argv[1]
screenshot_path = f"/tmp/loop_{device_id}.png"

# Captura de pantalla
screenshot = subprocess.check_output(["adb", "-s", device_id, "exec-out", "screencap", "-p"])
with open(screenshot_path, "wb") as f:
    f.write(screenshot)

img = cv2.imread(screenshot_path)
if img is None:
    print("error")
    sys.exit()

# Diccionario de plantillas: estado -> archivo PNG
templates = {
    "off": "loop_off.png",
    "playlist": "loop_on_playlist.png",
    "song": "loop_on_song.png"
}

threshold = 0.75
best_match = None
best_val = 0

for estado, template_path in templates.items():
    template = cv2.imread(template_path)
    if template is None:
        continue

    result = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED)
    _, max_val, _, max_loc = cv2.minMaxLoc(result)

    if max_val > best_val and max_val >= threshold:
        best_match = (estado, max_loc, template.shape[1], template.shape[0])
        best_val = max_val

if best_match is not None:
    estado, (x, y), w, h = best_match
    center_x = x + w // 2
    center_y = y + h // 2
    print(f"{estado} {center_x} {center_y}")
else:
    print("not_found")

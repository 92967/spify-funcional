import cv2
import numpy as np
import subprocess
import sys
import os

device_id = sys.argv[1]
filename = f"screen_{device_id}.png"

# Captura de pantalla a archivo
with open(filename, "wb") as f:
    subprocess.run(["adb", "-s", device_id, "exec-out", "screencap", "-p"], stdout=f)

#Leer imagenes capturadas
img = cv2.imread(filename)
template = cv2.imread("play_ref.png")

#Buscar coincidencia
result = cv2.matchTemplate(img, template, cv2.TM_CCOEFF_NORMED)
_, max_val, _, max_loc = cv2.minMaxLoc(result)

#Definir umbral de coincidencia
threshold = 0.8
if max_val >= threshold:
    x, y = max_loc
    w, h = template.shape[1], template.shape[0]
    center_x = x + w // 2
    center_y = y + h // 2
    print(f"🎯 Tap en: {center_x} {center_y}")

#Pulsar boton en el dispositivo
    subprocess.run(["adb", "-s", device_id, "shell", "input", "tap", str(center_x), str(center_y)])
else:
    print("❌ Botón Play no encontrado")

# Eliminar captura individual
os.remove(filename)

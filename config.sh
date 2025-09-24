#!/bin/bash
# ─────────────── CONFIGURACIÓN GLOBAL ────────────────

# Token y chat de Telegram
TELEGRAM_TOKEN="token_telegram"
TELEGRAM_CHAT_ID="token_id"

# Playlist a reproducir
playlist_url="playlist_spotify"

# Coordenadas pantalla (ajusta a tu modelo)
tap_play_x=624;   tap_play_y=738
tap_bottom_x=360; tap_bottom_y=1415
tap_loop_x=660;   tap_loop_y=1270

#Reiniciar ADB
adb kill-server
sleep 3
adb start-server

# Detectar automáticamente los dispositivos conectados por ADB
devices=($(adb devices | awk 'NR>1 && $2=="device" {print $1}'))

# Estado global
reproduccion_activa="variables_globales/reproduccion_activa.txt"
estado="variables_globales/estado.txt"
echo "parado" > "$estado"
echo "true" > "$reproduccion_activa"
for d in "${devices[@]}"; do cambiando_cancion["$d"]="false"; done

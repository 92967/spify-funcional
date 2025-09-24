#!/bin/bash
# ─────────────── FUNCIONES TELEGRAM ────────────────

log() {
  echo "$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" -d text="$1" >/dev/null
}

enviar_pantallazos() {
  cantidad_dispositivos=$(adb devices | grep -w "device" | grep -v "List" | wc -l)
    if [ "$cantidad_dispositivos" -lt 6 ]; then
      log "Dispositivo desconectado. $cantidad_dispositivos dispositivos encontrados. Reiniciando adb "
      adb kill-server
      sleep 3
      adb start-server
      cantidad_dispositivos=$(adb devices | grep -w "device" | grep -v "List" | wc -l)
      log "ADB Reiniciado. $cantidad_dispositivos dispositivos encontrados"
    fi

  log "📸 Enviando capturas…"
  for d in "${devices[@]}"; do
    f="/tmp/screenshot_$d.png"
    adb -s "$d" exec-out screencap -p > "$f"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendPhoto" \
      -F chat_id="$TELEGRAM_CHAT_ID" -F caption="Dispositivo $d" -F photo=@"$f"
    rm -f "$f"
  done
}

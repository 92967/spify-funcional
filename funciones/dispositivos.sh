#!/bin/bash
# ─────────────── FUNCIONES DISPOSITIVOS ────────────────

cerrar_apps() {
  log "🧹 Cerrando apps…"
  for d in "${devices[@]}"; do
    adb -s "$d" shell input keyevent KEYCODE_APP_SWITCH
    sleep 1
    adb -s "$d" shell input swipe 500 1000 500 300
    sleep 1
    adb -s "$d" shell input keyevent KEYCODE_HOME
  done
}

modo_avion_ciclo() {
  log "📴 Modo avión 10 s…"
  for d in "${devices[@]}"; do
    adb -s "$d" shell settings put global airplane_mode_on 1
    adb -s "$d" shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
  done
  sleep 10
  for d in "${devices[@]}"; do
    adb -s "$d" shell settings put global airplane_mode_on 0
    adb -s "$d" shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
  done
}
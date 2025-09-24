#!/bin/bash
# shellcheck disable=SC2154
# ─────────────── FUNCIONES REPRODUCCIÓN ────────────────

abrir_spotify() {
  log "🎵 Abriendo playlist…"
  for d in "${devices[@]}"; do
    adb -s "$d" shell am start -a android.intent.action.VIEW -d "$playlist_url"
  done
  sleep 7
}

dar_play() {
  log "▶️ Detectando y pulsando Play..."
  sleep 1
  for d in "${devices[@]}"; do
    python3 detectar_play.py "$d"
  done
}

abrir_cancion() {
  for d in "${devices[@]}"; do
    adb -s "$d" shell input tap "$tap_bottom_x" "$tap_bottom_y"
  done
}

detectar_estado_bucle() {
  for d in "${devices[@]}"; do
    sleep 1
    resultado=$(python3 detectar_estado_bucle.py "$d")
    if [[ "$resultado" == "not_found" || "$resultado" == "error" ]]; then
      log "❌ No se pudo detectar el botón de bucle en $d"
      continue
    fi

    estado_bucle=$(echo "$resultado" | awk '{print $1}')
    x=$(echo "$resultado" | awk '{print $2}')
    y=$(echo "$resultado" | awk '{print $3}')
      log "📍 Coordenadas detectadas en $d: estado=$estado_bucle, x=$x, y=$y"

    # 👉 Verificar que x e y sean números válidos
    if [[ -z "$x" || -z "$y" || ! "$x" =~ ^[0-9]+$ || ! "$y" =~ ^[0-9]+$ ]]; then
      log "⚠️ Coordenadas inválidas para $d ($estado_bucle) — se omite tap"
      continue
    fi

    case "$estado_bucle" in
      off)
        log "🔁 Activando bucle en $d (estado: off)"
        sleep 2
        adb -s "$d" shell input tap "$x" "$y"
        ;;
      playlist)
        log "🔁 Activando bucle en $d (estado: playlist)"
        sleep 2
        adb -s "$d" shell input tap "$x" "$y"
        sleep 2
        adb -s "$d" shell input tap "$x" "$y"
        sleep 2
        adb -s "$d" shell input tap "$x" "$y"
        ;;
      song)
        log "🔁 Activando bucle en $d (estado: bucle de cancion)"
        sleep 2
        adb -s "$d" shell input tap "$x" "$y"
        log "✔️ Bucle ya activado en $d (estado: bucle de cancion)"
        ;;
      *)
        log "❓ Estado no reconocido para $d: '$estado_bucle'"
        ;;
    esac

    # Borrar captura
    rm -f "/tmp/loop_${d}.png"
  done
}

# --------------- motor principal ---------------
iniciar_reproduccion() {
  reproduccion_activa="variables_globales/reproduccion_activa.txt"
  estado="variables_globales/estado.txt"
  #Reiniciar ADB
  adb kill-server
  sleep 3
  adb start-server
  devices=($(adb devices | awk 'NR>1 && $2=="device" {print $1}'))
  [ "$(cat "$estado")" = "reproduciendo" ] && { log "⚠️ Ya en marcha"; return; }

  echo "reproduciendo" > "$estado"
  echo "true" > "$reproduccion_activa"

  log "Ejecutando bot"

  cerrar_apps
  abrir_spotify
  dar_play
  abrir_cancion
  detectar_estado_bucle

  log "bucle playlist"

  while [ "$(tail -n 1 "$estado")" = "reproduciendo" ]; do
    # 1. Calcular ciclo de 3-4 horas
    total_seg=$(( RANDOM % 3600 + 10800 ))
    log "🕒 Iniciando ciclo de reproducción de $(( total_seg / 60 )) minutos"
    seg_transcurridos=0

    # 2. Sub-bucle: cambio de canción cada 40–95 seg
    while [ "$seg_transcurridos" -lt "$total_seg" ] && [ "$(cat "$estado")" = "reproduciendo" ]; do
      if [ "$(tail -n 1 "$reproduccion_activa")" != "true" ]; then sleep 1; continue; fi

      cantidad_dispositivos=$(adb devices | grep -w "device" | grep -v "List" | wc -l)
      if [ "$cantidad_dispositivos" -lt 6 ]; then
        log "Dispositivo desconectado. $cantidad_dispositivos dispositivos encontrados. Reiniciando adb "
        adb kill-server
        sleep 3
        adb start-server
      cantidad_dispositivos=$(adb devices | grep -w "device" | grep -v "List" | wc -l)
        log "ADB Reiniciado. $cantidad_dispositivos dispositivos encontrados"
      fi
      espera=$(( RANDOM % 56 + 40 ))  # 40–95 seg
      log "🕐 Esperando $espera s antes de cambiar canción"
      sleep "$espera"
      seg_transcurridos=$(( seg_transcurridos + espera ))

      for d in "${devices[@]}"; do
        adb -s "$d" shell input keyevent KEYCODE_MEDIA_NEXT
      done

      log "⏭️ Canción siguiente (t ~ $(( seg_transcurridos / 60 )) min de $(( total_seg / 60 )) min)"
    done

    cantidad_dispositivos=$(adb devices | grep -w "device" | grep -v "List" | wc -l)
      if [ "$cantidad_dispositivos" -lt 6 ]; then
        log "Ciclo terminado. $cantidad_dispositivos dispositivos encontrados. Reiniciando adb para reiniciar dispositivos. "
        adb kill-server
        sleep 3
        adb start-server
      fi

    # 3. Proceso de reinicio
    cerrar_apps
    log "📴 Activando modo avión"
    for d in "${devices[@]}"; do
      adb -s "$d" shell settings put global airplane_mode_on 1
      adb -s "$d" shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state true
    done

    sleep 15

    log "📶 Desactivando modo avión"
    for d in "${devices[@]}"; do
      adb -s "$d" shell settings put global airplane_mode_on 0
      adb -s "$d" shell am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
    done

    log "⏳ Esperando 30 min antes de reiniciar ciclo"
    sleep 1800

    # 4. Volver a iniciar reproducción
    cerrar_apps
    abrir_spotify
    dar_play
    abrir_cancion
    detectar_estado_bucle
  done
}


detener_reproduccion() {
  reproduccion_activa="variables_globales/reproduccion_activa.txt"
  estado="variables_globales/estado.txt"
  PID_play="$1"
  if [ "$(cat "$estado")" = "parado" ]; then
    log "⚠️ Ya parado"
    return
  fi

  echo "parado" > "$estado"
  echo "false" > "$reproduccion_activa"  
  kill "$PID_play"
  cerrar_apps
  modo_avion_ciclo
  log "⏸️ Pausado; espera /play para reanudar"
}


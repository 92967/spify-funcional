#!/bin/bash
# ───── main.sh: punto de entrada ─────

# Rutas relativas
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASE_DIR/config.sh"

# Importar módulos
for f in "$BASE_DIR/funciones/"*.sh; do source "$f"; done

log "¡Hola! Ya estoy disponible para usar, usa /play para comenzar"

# Offset inicial
offset=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates" | \
         jq '(.result[-1].update_id // 0) + 1')

PID_play=1

# Bucle de escucha
while true; do
  resp=$(curl -s "https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates?offset=$offset")
  for msg in $(echo "$resp" | jq -c '.result[]'); do
    text=$(echo "$msg" | jq -r '.message.text')
    chat=$(echo "$msg" | jq -r '.message.chat.id')
    upd=$(echo "$msg"  | jq -r '.update_id'); offset=$((10#$upd + 1))
    [[ "$chat" != "$TELEGRAM_CHAT_ID" ]] && continue

    case "$text" in
      /play) iniciar_reproduccion &
        PID_play=$! ;;
      /stop) detener_reproduccion "$PID_play" ;;
      /bucle) detectar_estado_bucle ;;
      /pantallazo) enviar_pantallazos ;;
    esac
  done
  sleep 2
done

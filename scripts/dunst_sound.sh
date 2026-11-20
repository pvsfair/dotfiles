#!/bin/sh

# O Dunst passa o Summary automaticamente como o segundo argumento ($2)
# SUMMARY="$2"

# BODY="$2"
SUMMARY="$SWAYNC_SUMMARY"
BODY="$SWAYNC_BODY"

# echo "$(date): Received alert -> $SUMMARY: $BODY" >> /tmp/kiro_notifications.log

if echo "$SUMMARY" | grep -iq "Response complete"; then
    # Som de Sucesso
    paplay /usr/share/sounds/Yaru/stereo/complete.oga
elif echo "$SUMMARY" | grep -iq "required"; then
    # Som de Alerta / Human-in-the-loop
    paplay /usr/share/sounds/Yaru/stereo/dialog-question.oga
elif echo "$SUMMARY" | grep -iq "Failure"; then
    # Som de Erro do Kiro CLI
    paplay /usr/share/sounds/Yaru/stereo/dialog-error.oga
fi

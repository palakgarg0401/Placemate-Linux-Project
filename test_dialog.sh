#!/bin/bash

CHOICE=$(dialog --title "Test Menu" \
    --menu "Choose one:" 10 40 3 \
    1 "Say Hello" \
    2 "Exit" \
    3>&1 1>&2 2>&3)

if [ "$CHOICE" == "1" ]; then
    dialog --msgbox "Hello from dialog!" 6 30
fi

clear

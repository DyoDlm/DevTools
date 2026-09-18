#!/bin/bash
#


FILE='/home/linuxconfig/scanned.log'
LOG_FILE='/home/linuxconfig/wifi_connection.log'
WIFIS=()
WIFI_CONNECTED=""

nmcli | grep "connecté à" > $FILE

string=$(cat $FILE)
salon=$(cat $FILE | grep "sgu-16425")
room=$(cat $FILE | grep "TP-Link_05A1")

if [[ -z $room ]]; then
	echo ""
	
    if [[ -z $salon ]]; then
		
        if [[ -n $string ]]; then
            echo not at home > $LOG_FILE
         #   sleep 30
		    exit
        fi
	else
		WIFI_CONNECTED="sgu-16425"
	fi
else
	WIFI_CONNECTED="TP-Link_05A1"
fi

date=$(date)

echo Last log : $date > $LOG_FILE

echo Connecte a : $WIFI_CONNECTED >> $LOG_FILE

nmcli dev wifi | sudo grep Mbit > $FILE

while IFS="\n" read line; do
    WIFIS+=("$line")
done < "$FILE"

#!/bin/bash

max_signal=1
best_wifi=""
best_ssid=""
best_name=""
best=0
i=0
while IFS= read -r wifi; do
    # Ignorer les lignes vides
    if [[ -z "$wifi" ]]; then
        continue
    fi

    ssid=$(echo "$wifi" | awk '{print $2}')
    name=$(echo "$wifi" | awk '{print $1}')
    signal=$(echo "$wifi" | awk '{print $7}')
    if [[ $signal == "Mbit/s" ]] ;then
        signal=0
    fi
    if (( $signal == 130 )); then
        signal=0
    fi
    # Vérifier que le signal est un nombre entier
    if [[ "$signal" =~ ^[0-9]+$ ]]; then
        if (( signal > max_signal )); then
            max_signal=$signal
            best_wifi="$wifi"
            best_ssid="$ssid"
            best_name="$name"
            best=$i
        fi
    fi

    ((i++))
done < 'scanned.log'

tmp=$best_name
best_name=$best_ssid
best_ssid=$tmp


# Affichage des résultats (optionnel)
echo "Meilleur WiFi trouvé :"
echo "Nom : $best_name"
echo "SSID : $best_ssid"
echo "Signal : $max_signal"
echo "Ligne complète : $best_wifi"


if [[ $best_name == "guestbitch" ]]; then
	best_name="sgu-16425"
fi

if [[ $best_name == "TP-Link_05A1_5G" ]]; then
	best_name="TP-Link_05A1"
fi

if [[ $best_name == $WIFI_CONNECTED ]] ; then 
	echo Already connected to best wifi >> $LOG_FILE
	exit
fi
echo Best : $best_name >> $LOG_FILE

case $best_name in 
	"sgu-16425")
		echo Switching to SALON WIFI >> $LOG_FILE
		nmcli d wifi connect sgu-16425 password b191-9kux-wvgb-nnrn;;

	"guestbitch")
		echo Switching to SALON WIFI >> $LOG_FILE
		nmcli d wifi connect sgu-16425 password b191-9kux-wvgb-nnrn;;

	"TP-Link_05A1")
		echo Switching to ROOM WIFI >> $LOG_FILE
		nmcli d wifi connect "30:68:93:FB:05:A1" password "PassSword657""!""123";;

	"") echo Wifi not known >> $LOG_FILE;;
esac


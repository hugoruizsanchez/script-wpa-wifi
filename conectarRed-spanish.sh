# !/bin/bash
# Author: Hugo Ruiz
# CONTROL DE CONEXIONES WIFI

# Este script se encarga de conectar a una red wifi. Puede editarse mediante parámetros.
# -> para editarla mediante parámetros: ./configurar_red nombredered contraseña

# CÓDIGOS DE COLOR

rojo="e[31m"
verde="e[32m"
amarillo="e[33m"
azul="e[34m"
negrita="e[1m"
reset="e[0m"

# INTRODUCCIÓN AL PROGRAMA

sudo echo -e "${negrita}*-------------------------------------*"
echo -e "| Script de conexiones Wi-Fi - WPA (wpa_supplicant)  |"
echo -e "| [ ] Script de inicio y configuración de redes      |"
echo -e "| [ ] Hugo R.S -> github.com/hugoruizsanchez         |"
echo -e "*----------------------------------------------------*${reset}"
echo ""

while true; do

    # ACTIVACION DE LA TARJETA DE RED

    sudo ifconfig wlan0 up

    echo -e " ${negrita} ${verde}[ ]${reset} ${negrita}Tarjeta de red wlan0 activada. ${reset}"

    # VERIFICACIÓN INICIAL DE IP (Comprobar si el usuario ya está conectado)

    ip_status=$(ip addr show dev wlan0 | grep "inet ")
    red_status=$(sudo curl -I www.google.com 2>&1 | grep "HTTP")

    if [ -n "$red_status" ] && [ -z "$1" ] && [ -z "$2" ]; then

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} El equipo ya está conectado a internet, el estado actual de la tarjeta de red es: ${reset}"
        echo ""
        sudo iwconfig wlan0

    else

        if [ -n "$ip_status" ] && [ -n "$1" ] && [ -n "$2" ] ]; then

            echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita}Se encuentra conectado a una red, pero ha introducido parámetros nuevos. ${reset}"
            echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita}Desconectado de internet.${reset}"

            sudo wpa_cli -i wlan0 disconnect >/dev/null
            sudo killall wpa_supplicant

            echo -e " ${negrita} ${verde}[!]${reset} ${negrita}Conexión desconectada.${reset}"

        else

            echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita}No se encuentra conectado a ninguna red estable, el estado actual de su tarjeta de red es: ${reset}"

        fi

        echo ""

        sudo iwconfig wlan0

        # MOSTRAR COENXIONES DISPONIBLES

        echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} Antes de proseguir, verifique el estado de las conexiones: ${reset}"

        iwlist wlan0 scanning | grep -E "ESSID|Bit Rates|WPA"

        # DECLARACIÓN DE PARÁMETROS

        nombre=$1
        pass=$2

        # EXPORTACIÓN DE ARCHIVO SI HAY PARÁMETROS

        if [ -n "$1" ] && [ -n "$2" ]; then # -> Si parametro 1 ($1) y parametro 2 ($2) existen...

            echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Ha introducido parametros. Sobreescribiendo /$USER/.config/configuracion_red.conf ${reset}"

            sudo wpa_passphrase $nombre $pass >/home/$USER/.config/configuracion_red.conf # -> Exportar fichero de configuracion a .config

            echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Configuración guardada en home/$USER/.config/configuracion_red.conf ${reset}"

        else # -> ... si no...

            echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} No se han introducido parámetros. Esto puede suceder porque se trata de una sesión de inicio. ${reset}"

        fi

        # COMPROBAR EXISTENCIA DEL FICHERO DE CONFIGURACIÓN

        if [ ! -f "/home/$USER/.config/configuracion_red.conf" ]; then # Si el archivo ! existe (f), entonces...

            echo -e " ${negrita} ${rojo}[-]${reset} ${negrita} Archivo de configuración no encontrado, para proseguir, ejecute nuevamente el script con los parámetros nombredered y contraseña en el bash. ${reset}"

            exit 0

        fi

        # CONEXIÓN A LA RED MEDIANTE EL ACCESO A configuracion_red.conf

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Archivo de configuración encontrado en /$USER/.config/configuracion_red.conf. ${reset}"

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Vinculando la red mediante el fichero configuracion_red.conf. ${reset}"

        sudo wpa_supplicant -B -i wlan0 -c /home/$USER/.config/configuracion_red.conf >/dev/null # Iniciar sesión en la red con el fichero.

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Red vinculada, pero no conectada. Necesaria comprobación y asignación de IP. ${reset}"

    fi

    # CONFIGURACIÓN DE IP

    echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} Configurando dirección IP. ${reset}"

    sudo dhclient -v wlan0 >/dev/null 2>&1 # -> Asignar la IP para llevar a cabo la conexión

    # VERIFICAR IP

    ip_status=$(ip addr show dev wlan0 | grep "inet ")

    if [ -n "$ip_status" ]; then

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Dirección IP asignada exitosamente.El equipo ya está conectado a internet, el estado actual de la tarjeta de red es: ${reset}"
        echo ""

        sudo iwconfig wlan0

        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Y la dirección IP con la que se conecta es: ${reset}"
        echo ""

        sudo ip addr show dev wlan0 | grep "inet "

        break

    else

        echo -e " ${negrita} ${rojo}[-]${reset} ${negrita} Red no conectada, problemas de conexión. ${reset}"
        echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} ¿Desea reintentar? S/N ${reset}"
        read -p "     -> " input

        if [ "$input" != "S" ]; then
            exit 0
        fi

    fi
done

echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} ¿Iniciar proceso de verificación constante de conexión? S/N ${reset}"

read -p "     -> " input

if [ "$input" != "S" ]; then
    exit 0
fi

while true; do

    red_status=$(sudo curl -I www.google.com 2>&1 | grep "HTTP")

    sleep 1

    if [ -z "$red_status" ]; then
        echo -e " ${negrita} ${rojo}[-]${reset} ${negrita} Conexión caída, intentando reconectar. ${reset}"
        echo -e " ${negrita} ${amarillo}[!]${reset} ${negrita} Configurando dirección IP. ${reset}"
        sudo dhclient -v wlan0 >/dev/null 2>&1 # -> Asignar la IP para llevar a cabo la conexión
    else
        echo -e " ${negrita} ${verde}[ ]${reset} ${negrita} Conexión establecida. ${reset}"
        ping google.com -c 1 2>&1 | grep "bytes"
        echo ""
    fi

done

# FIN DEL PROGRAMA watch -n 5

menu() {
	if [[ $EUID -ne 0 ]]; then
		echo "Debes ser root para poder ejecutarlo (pon sudo delante del comando de ejecucion del script)"
		exit 1
	fi
	while true; do
		clear
		echo "----------------------------------------------------------"
		echo "| Servicio de Audio Script realizado por Jorge del Horno |"
		echo "----------------------------------------------------------"
		echo "-----------------------------------------------"
		echo "| DEBES TENER PERMISOS DE SUDO PARA EJECUTARLO |"
		echo "-----------------------------------------------"
		echo "0. Conocer la informacion del equipo/red"
		echo "1. Conocer el status de pulseaudio"
		echo "2. Instalar Pulseaudio"
		echo "	2.1 Configurar Pulseaudio"
		echo "3. Eliminar Pulseaudio"
		echo "4. Iniciar Pulseaudio"
		echo "5. Detener Pulseaudio"
		echo "6. Desactivar PipeWire"
		echo "8. Consultar Logs"
		echo "9. Salir"
	read -p "Elige una opcion: " opcion
	case $opcion in
		0) echo ""
		echo -e "\e[38;5;75mEsta es la informacion de red del pc:\e[0m"
		echo "Direccion IP: $(hostname -I | awk '{print $1}')"
		echo "Nombre del host: $(hostname)"
		echo "Interfaz de red: $(ip route | grep default | awk '{print $5}')"
		echo ""
		;;

		1) echo ""
		echo -e "\e[38;5;75mEste es el status de pulseaudio actualmente..\e[0m"
		SERVICIO="pulseaudio"
		VERSION=$(pulseaudio --version 2>/dev/null)

		if [ -n "$VERSION" ]; then
			echo -e "\e[31m$SERVICIO esta activado con esta version: $VERSION\e[0m"
		else
			echo -e "\e[31m$SERVICIO no esta activado\e[0m"
		fi
		echo ""
		;;

		2) echo ""
		SERVICIO="pulseaudio"
                VERSION=$(pulseaudio --version 2>/dev/null)

                if [ -n "$VERSION" ]; then
                        echo -e "\e[31m$SERVICIO esta activado con esta version: $VERSION\e[0m"
                else
                        echo -e "\e[38;5;75mInstalando Pulseaudio ..\e[0m"
               		sudo apt update && sudo apt install -y pulseaudio pavucontrol paprefs pulseaudio-utils telnet ufw mpv
                	echo ""
               	 	echo "pulseaudio se ha intalado correctamente"
                	echo ""
                fi
		;;
		2.1) echo ""
		IP_LOCAL=$(hostname -I | awk '{print $1}')

		echo "La IP del equipo es $IP_LOCAL"
		read -p "¿Este es el equipo servidor o cliente? (s/c): " TIPO

		if [[ "$TIPO" == "s" ]]; then
			echo -e "\e[38;5;75mConfigurando el servicio de Pulseaudio como servidor\e[0m"

			CONF_PULSE="/etc/pulse/default.pa"
			echo "Configurando $CONF_FILE"
			sudo sed -i 's/^#load-module module-native-protocol-tcp/load-module module-native-protocol-tcp auth-ip-acl=0.0.0.0/g' $CONF_PULSE
			sudo sed -i 's/^#load-module module-alsa-sink/load-module module-alsa-sink/g' $CONF_PULSE
			sudo sed -i 's/^#load-module module-suspend-on-idle/#load-module module-suspend-on-idle/g' $CONF_PULSE

			sudo ufw allow 4713/tcp
			echo "Puerto 4713 abierto"

			echo "Configurando Paprefs"
			LIB_PULSE=$(ls /usr/lib | grep pulse)
			ln -s /usr/lib/$LIB_PULSE /usr/lib/pulse-16.1
			echo "Configuracion de Paprefs completada"
			echo -e "\e[32mSERVICIO DE AUDIO CONFIGURADO COMPLETAMENTE\e[0m"

		elif [[ "$TIPO" == "c" ]]; then
			echo -e "\e[38;5;75mConfigurando Pulseaudio como cliente\e[0m"

			read -p "Ingrese la IP del servidor de Pulseaudio: " IP_SERVIDOR

			echo "export PULSE_SERVER=tcp:$UP_SERVIDOR" >> ~/.bashrc
			source ~/.bashrc

			echo "Cliente configurado para conectarse a $IP_SERVIDOR"
			exec bash
		else
			echo "No has seleccionado una opcion valida"
			exit 1
		fi

		echo "Configuracion completada"
		;;
		3) echo""
		echo -e "\e[38;5;75mEliminando Pulseaudio, Paprefs, Pulseaudio-utils, Pavucontrol ..\e[0m"
		echo ""
		sudo dpkg --configure -a
                sudo apt install -f -y
		sudo apt remove --purge -y pulseaudio pulseaudio-utils pavucontrol paprefs libpulse0 mpv libavdevice60 libavfilter9
		sudo apt autoremove -y && sudo apt clean
		sudo rm -rf /var/lib/dpkg/lock
		sudo rm -rf /var/lib/dpkg/lock-frontend
		sudo rm -rf /var/lib/apt/lists/*
		sudo rm -rf /var/cache/apt/archives/*.deb
		sudo apt update --fix-missing
		sudo apt upgrade -y
		echo ""
		echo "Borrando la configuracion y archivos"
		echo ""
		sudo rm -rf ~/.config/pulse ~/.pulse /etc/pulse /var/lib/pulse

		ELIMINAR=$(dpkg -l | grep pulseaudio)
		if [ -z "$ELIMINAR" ]; then
			echo "Se ha eliminado correctamente"
		else 
			echo "No se ha eliminado correctamente"
		fi
		;;
		4)echo ""
		if pgrep -x "pulseaudio" > /dev/null; then
			echo -e "\e[38;5;75mPulseaudio ya esta en ejecucion\e[0m"
		else
			echo -e "\e[38;5;75mIniciando Pulseaudio ..\e[0m"
		pulseaudio --start
                echo "Pulseaudio se ha iniciado"
		fi
		;;
		5)echo ""
		if pgrep -x "pulseaudio" > /dev/null; then
                	 echo -e "\e[38;5;75mDeteniendo Pulseaudio ..\e[0m"
			pulseaudio --kill
			echo "Pulseaudio se ha detenido"
		else
			echo -e "\e[38;5;75mPulseaudio ya esta detenido\e[0m"
		fi
		;;
		6) echo ""
		if systemctl is-enabled pipewire.service | grep -q "masked"; then
			echo "Pipewire ya esta desactivado"
                else
			echo -e "\e[38;5;75mDesactivando pipewire ..\e[0m"
			sudo systemctl stop pipewire.service
			sudo systemctl stop pipewire.socket
			sudo systemctl mask pipewire.service
			sudo systemctl mask pipewire.socket
			sudo systemctl disable pipewire.service
			echo "Pipewire se ha desactivado"
		fi
		;;
            8) echo ""
   echo "Seleccione una opcion a la hora de buscar los logs"
   echo "1. Logs generales del servicio de audio"
   echo "2. Logs por fechas del servicio de audio"
   echo "3. Logs en tiempo real del servicio de audio"
   echo "4. Logs segun el tipo que sean del servicio de audio"
   echo "5. Exportar logs con JSON del servicio de audio"
   read -p "Elige una opcion: " log_opcion

   case $log_opcion in
       1) echo ""
          echo -e '\e[38;5;75mMostrando logs generales del servicio de audio\e[0m'
          journalctl -u pulseaudio -u paprefs -u pulseaudio-utils --no-pager
          ;;
       2) echo ""
          read -p "Introduce la fecha de inicio (AA-MM-DD HH-MM-SS): " inicio
          read -p "Introduce la fecha de fin (AA-MM-DD HH-MM-SS): " fin
          echo -e "\e[38;5;75m Mostrando los logs desde $inicio a $fin\e[0m"
          journalctl -u pulseaudio -u paprefs -u pulseaudio-utils --since "$inicio" --until "$fin" --no-pager
          ;;
       3) echo ""
          echo -e "\e[38;5;75mMostrando logs en tiempo real (presiona enter para salir del apartado)\e[0m"
          journalctl -u pulseaudio -u paprefs -u pulseaudio-utils -f &
 	  LOG_PID=$! 
	  read -r -p ""
	  kill $LOG_PID 2>/dev/Null
          ;;
       4) echo ""
          echo -e "\e[38;5;75m Selecciona el tipo de error que deseas buscar\e[0m"
          echo ""
          echo "1. Logs de errores"
          echo "2. Logs de advertencias"
          echo "3. Logs de informacion"
          echo "4. Logs de depuracion"
          read -p "Elige una opcion: " log_tipo

          case $log_tipo in
              1) journalctl -u pulseaudio -u paprefs -u pulseaudio-utils -p 3 --no-pager ;;
              2) journalctl -u pulseaudio -u paprefs -u pulseaudio-utils -p 4 --no-pager ;;
              3) journalctl -u pulseaudio -u paprefs -u pulseaudio-utils -p 6 --no-pager ;;
              4) journalctl -u pulseaudio -u paprefs -u pulseaudio-utils -p 7 --no-pager ;;
              *) echo "Opcion no valida" ;;
          esac
          ;;
       5) echo ""
          read -p "Introduce el nombre del archivo para exportar (sin extension): " archivo
          journalctl -u pulseaudio -u paprefs -u pulseaudio-utils --output=json-pretty > "$archivo.json"
          echo "El archivo $archivo.json se ha exportado con exito"
          ;;
       *) echo "Opcion no valida, intentalo de nuevo" ;;
   esac
   ;;

 9) echo "Saliendo del script..."
               exit 0
               ;;
            
            *) echo "Opcion no valida, intentalo de nuevo" ;;
        esac
        read -p "Presiona Enter para volver al menu"
    done
}

menu


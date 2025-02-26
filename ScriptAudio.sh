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
		echo "3 Configurar Pulseaudio"
		echo "4. Eliminar Pulseaudio"
		echo "5. Iniciar Pulseaudio"
		echo "6. Detener Pulseaudio"
		echo "7. Desactivar PipeWire"
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
  		echo "Seleccione una opcion para instalar el servicio"
   		echo "1. Instalar con comandos"
  		echo "2. Instalar con Docker"
  		echo "3. Instalar con Ansible"
  		read -p "Elige una opcion: " instalar_opcion

  		case $instalar_opcion in

       		1) echo ""
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
			
			2) echo ""
		set -e

		instalar_docker() {
  				echo "Docker no está instalado. Se procederá a instalarlo..."
  				apt-get update
 				apt-get install -y docker.io
  				systemctl enable docker
  				systemctl start docker
  				echo "Docker se ha instalado y se está ejecutando."
			}

			if ! command -v docker >/dev/null 2>&1; then
  					instalar_docker
			fi

			DOCKERFILE="Dockerfile"
			IMAGE_NAME="servicio_audio"
			CONTAINER_NAME="audio_service"
			SCRIPT_AUDIO="ScriptAudio.sh"

			if [ ! -f "$SCRIPT_AUDIO" ]; then
 				 echo "El archivo $SCRIPT_AUDIO no se encuentra en el directorio actual."
  				exit 1
			fi

			echo "Creando Dockerfile para el servicio de audio"

			if [ -f "$DOCKERFILE" ]; then
  				echo "Eliminando Dockerfile existente"
  				rm -f "$DOCKERFILE"
			fi

			echo "from ubuntu:latest" >> $DOCKERFILE
			echo "" >> $DOCKERFILE
			echo "ENV DEBIAN_FRONTEND=noninteractive" >> $DOCKERFILE
			echo "" >> $DOCKERFILE
			echo "RUN apt-get update && apt-get install -y \\" >> $DOCKERFILE
			echo "    pulseaudio \\" >> $DOCKERFILE
			echo "    pavucontrol \\" >> $DOCKERFILE
			echo "    paprefs \\" >> $DOCKERFILE
			echo "    pulseaudio-utils \\" >> $DOCKERFILE
			echo "    telnet \\" >> $DOCKERFILE
			echo "    ufw \\" >> $DOCKERFILE
			echo "    mpv && \\" >> $DOCKERFILE
			echo "    apt-get clean" >> $DOCKERFILE
			echo "" >> $DOCKERFILE
			echo "COPY $SCRIPT_AUDIO /usr/local/bin/ScriptAudio.sh" >> $DOCKERFILE
			echo "RUN chmod +x /usr/local/bin/ScriptAudio.sh" >> $DOCKERFILE
			echo "" >> $DOCKERFILE
			echo "EXPOSE 4713" >> $DOCKERFILE
			echo "" >> $DOCKERFILE
			echo "CMD [\"bash\", \"/usr/local/bin/ScriptAudio.sh\"]" >> $DOCKERFILE

			echo "Dockerfile creado exitosamente."

			echo "Construyendo la imagen Docker $IMAGE_NAME ==="
			docker build -t $IMAGE_NAME .

			echo "Iniciando el contenedor: $CONTAINER_NAME ==="
			docker run --name $CONTAINER_NAME -it --privileged --network=host $IMAGE_NAME

			echo "El contenedor con el servicio de audio esta corriendo"

            ;;

            3) echo "Instalando Pulseaudio con Ansible..."
                  PLAYBOOK="install_audio.yml"

                  echo "---" > $PLAYBOOK
                  echo "- name: Instalar Pulseaudio" >> $PLAYBOOK
                  echo "  hosts: localhost" >> $PLAYBOOK
                  echo "  become: true" >> $PLAYBOOK
                  echo "  tasks:" >> $PLAYBOOK
                  echo "    - name: Actualizar repositorios" >> $PLAYBOOK
                  echo "      apt:" >> $PLAYBOOK
                  echo "        update_cache: yes" >> $PLAYBOOK
                  echo "    - name: Instalar Pulseaudio" >> $PLAYBOOK
                  echo "      apt:" >> $PLAYBOOK
                  echo "        name:" >> $PLAYBOOK
                  echo "          - pulseaudio" >> $PLAYBOOK
                  echo "          - pavucontrol" >> $PLAYBOOK
                  echo "          - paprefs" >> $PLAYBOOK
                  echo "          - pulseaudio-utils" >> $PLAYBOOK
                  echo "          - telnet" >> $PLAYBOOK
                  echo "          - ufw" >> $PLAYBOOK
                  echo "          - mpv" >> $PLAYBOOK
                  echo "        state: present" >> $PLAYBOOK
                  echo "    - name: Abrir puerto 4713 en firewall" >> $PLAYBOOK
                  echo "      ufw:" >> $PLAYBOOK
                  echo "        rule: allow" >> $PLAYBOOK
                  echo "        port: 4713" >> $PLAYBOOK
                  echo "        proto: tcp" >> $PLAYBOOK
                  echo "    - name: Configurar Pulseaudio" >> $PLAYBOOK
                  echo "      lineinfile:" >> $PLAYBOOK
                  echo "        path: /etc/pulse/default.pa" >> $PLAYBOOK
                  echo "        line: \"load-module module-native-protocol-tcp auth-ip-acl=0.0.0.0\"" >> $PLAYBOOK
                  echo "        insertafter: \"#load-module module-native-protocol-tcp\"" >> $PLAYBOOK
                  echo "        state: present" >> $PLAYBOOK
                  echo "    - name: Reiniciar Pulseaudio" >> $PLAYBOOK
                  echo "      shell: pulseaudio --kill && pulseaudio --start" >> $PLAYBOOK
                  echo "      ignore_errors: yes" >> $PLAYBOOK

                  echo "Ejecutando playbook..."
                  ansible-playbook $PLAYBOOK
                  echo "Instalacion con Ansible completada."
                  ;;
           esac
           ;;

		3) echo ""
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
		4) echo""
		echo -e "\e[38;5;75mEliminando Pulseaudio, Paprefs, Pavucontrol-Utils, Pavcontrol...\e[0m"

	if ! command -v sudo &> /dev/null; then
		echo "sudo no está instalado. Por favor, instálalo primero."
		exit 1
	fi

	sudo apt-get --configure -a
	sudo apt-get install -f -y
	sudo apt-get remove --purge -y pulseaudio pulseaudio-utils pavucontrol paprefs libpulse0 mpv libavdevice58

	sudo rm -rf /var/lib/dpkg/lock
	sudo rm -rf /var/lib/dpkg/lock-frontend
	sudo rm -rf /etc/apt/sources.list.d/
	sudo rm -rf /var/lib/apt/lists/*
	sudo apt-get autoclean

	echo "Borrando la configuración y archivos"
	rm -rf ~/.config/pulse /etc/pulse /var/lib/pulse

	ELIMINAR=$(dpkg -l | grep pulseaudio)
	if [ -z "$ELIMINAR" ]; then
			echo "Se ha eliminado correctamente"
	else
		echo "No se ha eliminado correctamente"
	fi
		;;
		5)echo ""
		if pgrep -x "pulseaudio" > /dev/null; then
			echo -e "\e[38;5;75mPulseaudio ya esta en ejecucion\e[0m"
		else
			echo -e "\e[38;5;75mIniciando Pulseaudio ..\e[0m"
		pulseaudio --start
                echo "Pulseaudio se ha iniciado"
		fi
		;;
		6)echo ""
		if pgrep -x "pulseaudio" > /dev/null; then
                	 echo -e "\e[38;5;75mDeteniendo Pulseaudio ..\e[0m"
			pulseaudio --kill
			echo "Pulseaudio se ha detenido"
		else
			echo -e "\e[38;5;75mPulseaudio ya esta detenido\e[0m"
		fi
		;;
		7) echo ""
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


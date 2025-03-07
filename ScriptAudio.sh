#!/bin/bash

menu() {
    if [[ $EUID -ne 0 ]]; then
        echo "Debes ser root para ejecutarlo (usa sudo)."
        exit 1
    fi
    while true; do
        clear
        echo "----------------------------------------------------------"
        echo "| Servicio de Audio - Script realizado por Jorge del Horno |"
        echo "----------------------------------------------------------"
        echo "0. Información del equipo/red"
        echo "1. Estado de Pulseaudio"
        echo "2. Instalar Pulseaudio"
        echo "3. Configurar Pulseaudio"
        echo "4. Eliminar Pulseaudio"
        echo "5. Iniciar Pulseaudio"
        echo "6. Detener Pulseaudio"
        echo "7. Desactivar PipeWire"
        echo "8. Consultar Logs"
        echo "9. Salir"
        read -p "Elige una opción: " opcion
        case $opcion in

        0) echo -e "\nInformación del equipo:" 
           echo "Dirección IP: $(hostname -I | awk '{print $1}')"
           echo "Nombre del host: $(hostname)"
           echo "Interfaz de red: $(ip route | grep default | awk '{print $5}')"
           ;;

        1) echo -e "\nEstado de Pulseaudio:"
         PROCESS="pulseaudio"
	if pgrep -x "$PROCESS" > /dev/null; then
    echo "El proceso $PROCESS está en ejecución."
	else
    echo "El proceso $PROCESS no está en ejecución."
	fi
	;;

        2) echo ""
  		echo "Seleccione una opcion para instalar el servicio"
   		echo "1. Instalar con comandos"
  		echo "2. Instalar con Docker"
  		echo "3. Instalar con Ansible"
  		read -p "Elige una opcion: " instalar_opcion

  		case $instalar_opcion in

       		1) echo ""
		echo "Instalando PulseAudio y herramientas"
		apt update && apt install -y pulseaudio pulseaudio-utils pavucontrol

		echo "Instalación completada"
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

            3) echo ""

echo "Instalando Pulseaudio con Ansible..."

if ! command -v ansible-playbook &> /dev/null; then
    echo "Ansible no está instalado. Instalando Ansible..."
    sudo apt update
    sudo apt install -y ansible
    if ! command -v ansible-playbook &> /dev/null; then
        echo "Error: No se pudo instalar Ansible. Por favor, instálalo manualmente."
        exit 1
    fi
fi

PLAYBOOK="install_audio.yml"

cat <<EOF > $PLAYBOOK
---
- name: Instalar Pulseaudio
  hosts: localhost
  become: true
  tasks:
    - name: Actualizar repositorios
      apt:
        update_cache: yes

    - name: Instalar Pulseaudio y herramientas adicionales
      apt:
        name:
          - pulseaudio
          - pavucontrol
          - paprefs
          - pulseaudio-utils
          - telnet
          - ufw
          - mpv
        state: present

    - name: Asegurar que el firewall permite conexiones en el puerto 4713
      ufw:
        rule: allow
        port: 4713
        proto: tcp

    - name: Configurar Pulseaudio para permitir conexiones remotas
      lineinfile:
        path: /etc/pulse/default.pa
        line: "load-module module-native-protocol-tcp auth-ip-acl=0.0.0.0"
        insertafter: "^#.*load-module module-native-protocol-tcp"
        state: present
      notify: Reiniciar Pulseaudio

  handlers:
    - name: Reiniciar Pulseaudio
      systemd:
        name: pulseaudio
        state: restarted
EOF

echo "Ejecutando playbook"
ansible-playbook $PLAYBOOK

echo "Instalación con Ansible completada"
;;
           esac
           ;;


        3) echo -e "\nConfigurando Pulseaudio..."
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

        4) echo "Eliminando PulseAudio y herramientas..."
	apt remove --purge -y pulseaudio pulseaudio-utils pavucontrol
	apt autoremove -y
	apt clean

	echo "Desinstalación completada"
        ;;

        5) echo -e "\nIniciando Pulseaudio..."
           export XDG_RUNTIME_DIR=/run/user/$(id -u)
           pulseaudio --start
           sleep 2
           if pgrep -x "pulseaudio" > /dev/null; then
               echo "Pulseaudio se ha iniciado correctamente."
           else
               echo "Error al iniciar Pulseaudio."
           fi
           ;;

        6) echo -e "\nDeteniendo Pulseaudio..."
           if pgrep -x "pulseaudio" > /dev/null; then

    	pulseaudio --kill
    	echo "Pulseaudio se ha detenido."
	else
    	echo "Pulseaudio ya está detenido."
	fi
           ;;

        7) echo "Desactivando PipeWire..."

	if pgrep -x "pipewire" > /dev/null; then
   	 pkill -x "pipewire"
    	echo "PipeWire se ha detenido."
	else
  	  echo "PipeWire ya está detenido."
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

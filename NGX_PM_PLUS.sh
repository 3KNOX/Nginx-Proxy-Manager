#!/bin/bash
###############################################################################
# NGINX PROXY MANAGER - PROXMOX INSTALLER v2.0
# Autor: 3KNOX
# Descripción: Instalador completo con menú, gestión de config, URL editor
# GitHub: https://github.com/3KNOX/Nginx-Proxy-Manager
###############################################################################

set -e

################################################################################
# SECCIÓN 1: COLORES Y CONSTANTES
################################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="/root/.npm_config"
LOG_FILE="/root/npm_installer.log"
SCRIPT_VERSION="2.9.0"

# Constantes de formato
MENU_WIDTH=59
HEADER_TOP="${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
HEADER_BOT="${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
MENU_TOP="${CYAN}┌───────────────────────────────────────────────────────────┐${NC}"
MENU_BOT="${CYAN}└───────────────────────────────────────────────────────────┘${NC}"

# Valores por defecto de URLs
DEFAULT_DOCKER_URL="https://get.docker.com"
DEFAULT_COMPOSE_VERSION="2.20.0"
DEFAULT_NPM_IMAGE="jc21/nginx-proxy-manager:latest"
DEFAULT_DB_IMAGE="jc21/mariadb-aria:latest"

################################################################################
# SECCIÓN 2: FUNCIONES AUXILIARES
################################################################################

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

show_header() {
    clear
    echo -e "$HEADER_TOP"
    echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER 🚀         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                        v${SCRIPT_VERSION}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              Created by: ${GREEN}3KNOX${CYAN}                        ║${NC}"
    echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
    echo -e "$HEADER_BOT"
    echo ""
}

# Función estándar para mostrar menús
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    show_header
    # Calcular espacios para centración
    local title_spaces=$((($MENU_WIDTH - ${#title}) / 2))
    printf "${CYAN}┌─ %*s%-*s ─┐${NC}\n" "$title_spaces" "" "$((${#title} + title_spaces))" "$title"
    echo ""
    
    for option in "${options[@]}"; do
        echo -e "  $option"
    done
    
    echo ""
    echo -e "$MENU_BOT"
    echo ""
}

################################################################################
# SECCIÓN 3: FUNCIONES DE CONFIGURACIÓN
################################################################################

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Limpiar el archivo si está corrupto (valores con emojis/caracteres especiales)
        if grep -q "^LAST_PROFILE=[^\"']" "$CONFIG_FILE" 2>/dev/null; then
            echo -e "${YELLOW}⚠ Archivo de configuración corrupto, reiniciando...${NC}"
            rm -f "$CONFIG_FILE"
            return 1
        fi
        source "$CONFIG_FILE" 2>/dev/null || {
            echo -e "${YELLOW}⚠ Error leyendo configuración, reiniciando...${NC}"
            rm -f "$CONFIG_FILE"
            return 1
        }
        echo -e "${GREEN}✓ Configuración cargada${NC}"
        return 0
    else
        return 1
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Configuración de NPM Installer - $(date)
LAST_VMID="$CTID"
LAST_HOSTNAME="$HOSTNAME"
LAST_NODE="$NODE"
LAST_BRIDGE="$BRIDGE"
LAST_PROFILE="$PROFILE"
LAST_CPU="$CPU"
LAST_RAM="$RAM"
LAST_DISK="$DISK"
LAST_BACKUP="$BACKUP"
LAST_CONTAINER_IP="$CONTAINER_IP"
LAST_CONTAINER_CIDR="$CONTAINER_CIDR"
LAST_CONTAINER_GATEWAY="$CONTAINER_GATEWAY"

# URLs configurables
DOCKER_URL=${DOCKER_URL:-$DEFAULT_DOCKER_URL}
COMPOSE_VERSION=${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}
NPM_IMAGE=${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}
DB_IMAGE=${DB_IMAGE:-$DEFAULT_DB_IMAGE}
EOF
    log_message "Configuración guardada en $CONFIG_FILE"
}

################################################################################
# SECCIÓN 4: FUNCIONES DE INTERFAZ (MENÚS)
################################################################################

show_main_menu() {
    local options=(
        "${GREEN}[1]${NC} 🟢 INSTALAR - Nivel NORMAL (512MB RAM | 1 CPU | 10GB)"
        "${YELLOW}[2]${NC} 🟡 INSTALAR - Nivel MEDIA (1GB RAM | 2 CPU | 15GB)"
        "${BLUE}[3]${NC} 🔵 INSTALAR - Nivel EXCELENTE (2GB RAM | 2 CPU | 20GB + Backups)"
        ""
        "${CYAN}[4]${NC} 🔄 REINSTALAR - Limpiar y recrear contenedor"
        "${CYAN}[5]${NC} ⬆️  ACTUALIZAR - Sistema + Docker + Imágenes"
        ""
        "${RED}[0]${NC} ❌ SALIR"
    )
    
    show_menu "MENÚ PRINCIPAL" "${options[@]}"
    read -p "$(echo -e "${GREEN}Elige opción${NC}") (0-5): " MAIN_OPTION
}

show_config() {
    local options=(
        "${CYAN}DATOS DEL CONTENEDOR:${NC}"
        "  📌 VMID: ${GREEN}${LAST_VMID:-No guardado}${NC}"
        "  📍 Hostname: ${GREEN}${LAST_HOSTNAME:-No guardado}${NC}"
        "  🖧 Nodo: ${GREEN}${LAST_NODE:-No guardado}${NC}"
        "  🌉 Bridge: ${GREEN}${LAST_BRIDGE:-No guardado}${NC}"
        "  ⚙️  Perfil: ${GREEN}${LAST_PROFILE:-No guardado}${NC}"
        ""
        "${CYAN}URLs CONFIGURADAS:${NC}"
        "  🔗 Docker: ${GREEN}${DOCKER_URL}${NC}"
        "  🔗 Compose: ${GREEN}${COMPOSE_VERSION}${NC}"
        "  🐳 Imagen NPM: ${GREEN}${NPM_IMAGE}${NC}"
        "  📦 Imagen BD: ${GREEN}${DB_IMAGE}${NC}"
        ""
        "${RED}[0]${NC} ← Volver al menú anterior"
    )
    
    if ! load_config; then
        options[0]="${YELLOW}⚠️  No hay configuración guardada aún${NC}"
        options=( "${options[@]:0:1}" )
    fi
    
    show_menu "CONFIGURACIÓN GUARDADA" "${options[@]}"
    read -p "Presiona Enter para volver..."
}

edit_urls() {
    show_header
    
    load_config || true
    
    echo -e "$MENU_TOP"
    echo ""
    
    local fields=("URL Docker" "COMPOSE_VERSION" "NPM_IMAGE" "DB_IMAGE")
    local defaults=("$DEFAULT_DOCKER_URL" "$DEFAULT_COMPOSE_VERSION" "$DEFAULT_NPM_IMAGE" "$DEFAULT_DB_IMAGE")
    local current=("${DOCKER_URL:-$DEFAULT_DOCKER_URL}" "${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}" "${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}" "${DB_IMAGE:-$DEFAULT_DB_IMAGE}")
    
    echo -e "  ${YELLOW}${fields[0]}:${NC}"
    echo -e "    Actual: ${GREEN}${current[0]}${NC}"
    read -p "    Nueva (Enter para mantener): " input
    DOCKER_URL="${input:-${current[0]}}"
    
    for i in 1 2 3; do
        echo ""
        label="${fields[$i]}"
        [[ "$label" == "COMPOSE_VERSION" ]] && label="Versión Compose"
        [[ "$label" == "NPM_IMAGE" ]] && label="Imagen NPM"
        [[ "$label" == "DB_IMAGE" ]] && label="Imagen BD"
        
        echo -e "  ${YELLOW}${label}:${NC}"
        echo -e "    Actual: ${GREEN}${current[$i]}${NC}"
        read -p "    Nueva (Enter para mantener): " input
        
        case $i in
            1) COMPOSE_VERSION="${input:-${current[$i]}}" ;;
            2) NPM_IMAGE="${input:-${current[$i]}}" ;;
            3) DB_IMAGE="${input:-${current[$i]}}" ;;
        esac
    done
    
    echo ""
    echo -e "$MENU_BOT"
    
    save_config
    echo -e "${GREEN}✓ URLs actualizadas correctamente${NC}"
    sleep 2
}

################################################################################
# SECCIÓN 5: FUNCIONES DE VALIDACIÓN
################################################################################

validate_template() {
    echo -e "${YELLOW}Buscando templates Debian en todos los storages...${NC}"
    
    # Obtener lista de storages desde pvesm status (compatible con todas las versiones)
    local templates=""
    local template_storage=""
    local all_storages=$(pvesm status 2>/dev/null | tail -n +2 | awk '{print $1}')
    
    # Buscar templates en cada storage (buscar en vztmpl, no en images)
    for storage in $all_storages; do
        templates=$(pvesm list "$storage:vztmpl" 2>/dev/null | grep -i "debian-13" | awk '{print $1}' | head -1)
        if [[ -n "$templates" ]]; then
            template_storage="$storage"
            echo -e "${GREEN}✓ Template encontrado: $templates${NC}"
            echo -e "${GREEN}✓ Storage: ${template_storage}${NC}"
            TEMPLATE="$templates"
            TEMPLATE_STORAGE="$template_storage"
            return 0
        fi
    done
    
    # Si no hay templates, descargar automáticamente
    if [[ -z "$templates" ]]; then
        echo -e "${YELLOW}⏳ No hay templates. Descargando automáticamente...${NC}"
        echo ""
        
        # Actualizar repositorio
        echo -e "${YELLOW}1. Actualizando repositorio de Proxmox...${NC}"
        pveam update 2>&1 | tail -1
        echo -e "${GREEN}✓ Repositorio actualizado${NC}"
        echo ""
        
        # Encontrar storage válido (preferir local type dir)
        local download_storage="local"
        echo -e "${YELLOW}2. Descargando template Debian 13...${NC}"
        
        # Obtener el nombre exacto del template disponible (segunda columna en la salida de pveam)
        local debian_template=$(pveam available 2>/dev/null | grep "debian-13-standard" | tail -1 | awk '{print $2}')
        
        # Si no está en la segunda columna, intentar primera
        if [[ -z "$debian_template" ]]; then
            debian_template=$(pveam available 2>/dev/null | grep "debian-13-standard" | tail -1 | awk '{print $1}')
        fi
        
        if [[ -z "$debian_template" ]]; then
            echo -e "${RED}❌ No hay templates Debian 13 disponibles${NC}"
            return 1
        fi
        
        echo -e "${CYAN}  → Template: $debian_template${NC}"
        echo -e "${CYAN}  → Storage: $download_storage${NC}"
        echo ""
        
        # Descargar template con indicador de progreso
        echo -e "${YELLOW}3. Descargando ${debian_template}...${NC}"
        echo -e "${CYAN}   (Esto puede tardar 5-15 minutos según tu conexión)${NC}"
        echo ""
        
        # Ejecutar descarga mostrando salida completa
        echo -e "${YELLOW}Iniciando descarga...${NC}"
        
        # Crear archivo temporal para log
        local download_log="/tmp/pveam_download_$$.log"
        
        # Descargar en background con log
        pveam download "$download_storage" "$debian_template" > "$download_log" 2>&1 &
        local download_pid=$!
        
        # Mostrar spinner mientras se descarga
        local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local i=0
        
        while kill -0 $download_pid 2>/dev/null; do
            printf "\r${CYAN}  %s Descargando...${NC}" "${spinner[$((i % ${#spinner[@]}))]}"
            ((i++))
            sleep 0.5
        done
        
        # Esperar a que termine
        wait $download_pid
        local download_status=$?
        
        echo ""
        echo ""
        
        # Mostrar resultado
        if [[ $download_status -eq 0 ]]; then
            echo -e "${GREEN}✓ Template descargado correctamente${NC}"
        else
            echo -e "${YELLOW}⚠️  Descarga completada${NC}"
        fi
        
        # Mostrar últimas líneas del log si hay error
        if [[ $download_status -ne 0 ]] && [[ -f "$download_log" ]]; then
            echo -e "${YELLOW}Detalles:${NC}"
            tail -3 "$download_log" | sed 's/^/  /'
        fi
        
        # Limpiar archivo temporal
        rm -f "$download_log"
        
        echo ""
        echo -e "${YELLOW}4. Procesando y indexando template...${NC}"
        echo -e "${CYAN}   (Esperando a que Proxmox indexe el archivo)${NC}"
        
        # Esperar a que Proxmox indexe el template
        local max_attempts=12
        local attempt=1
        local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        
        while [[ $attempt -le $max_attempts ]]; do
            # Mostrar spinner
            printf "\r${CYAN}  %s Intento %d/%d (espera ~%d segundos)${NC}" \
                "${spinner[$((($attempt-1) % ${#spinner[@]}))]}" \
                "$attempt" \
                "$max_attempts" \
                "$(((max_attempts - attempt) * 10))"
            
            # Buscar en pvesm
            local found=0
            for storage in $all_storages; do
                templates=$(pvesm list "$storage:vztmpl" 2>/dev/null | grep -i "debian-13" | awk '{print $1}' | head -1)
                if [[ -n "$templates" ]]; then
                    template_storage="$storage"
                    found=1
                    break
                fi
            done
            
            # Si encontramos en pvesm, salir
            if [[ $found -eq 1 ]]; then
                echo -e "\n${GREEN}✓ Template indexado en pvesm: ${template_storage}${NC}"
                break
            fi
            
            # Si no, buscar directamente en filesystem como respaldo
            if [[ $attempt -gt 3 ]]; then
                local fs_template=$(find /var/lib/vz/template/cache -name "*debian-13*" -type f 2>/dev/null | head -1)
                if [[ -n "$fs_template" ]]; then
                    echo -e "\n${GREEN}✓ Template encontrado en filesystem: $(basename $fs_template)${NC}"
                    templates=$(basename "$fs_template")
                    template_storage="$download_storage"
                    found=1
                    break
                fi
            fi
            
            # Si no encontramos y hay más intentos, esperar
            if [[ $found -eq 0 ]] && [[ $attempt -lt $max_attempts ]]; then
                sleep 10
            fi
            
            ((attempt++))
        done
        
        if [[ -z "$templates" ]]; then
            echo -e "\n${RED}❌ Template no disponible después de varios intentos.${NC}"
            return 1
        fi
    fi
    
    # Guardar storage de templates para usarlo luego
    TEMPLATE_STORAGE="$template_storage"
    
    # Si hay una sola, seleccionarla automáticamente
    local template_count=$(echo "$templates" | wc -l)
    if [[ $template_count -eq 1 ]]; then
        TEMPLATE="$templates"
        echo -e "${GREEN}✓ Template seleccionada: ${TEMPLATE}${NC}"
        return 0
    fi
    
    # Si hay múltiples, permitir seleccionar
    echo -e "${CYAN}Templates disponibles en ${template_storage}:${NC}"
    local i=1
    declare -a template_array
    while IFS= read -r template; do
        if [[ -n "$template" ]]; then
            echo "  [$i] $template"
            template_array[$i]="$template"
            ((i++))
        fi
    done < <(printf '%s\n' $templates)
    
    echo ""
    while true; do
        read -p "$(echo -e "${YELLOW}Elige template${NC}") (1-$((i-1))): " template_choice
        if [[ "$template_choice" =~ ^[0-9]+$ ]] && [[ $template_choice -ge 1 ]] && [[ $template_choice -lt $i ]]; then
            TEMPLATE="${template_array[$template_choice]}"
            echo -e "${GREEN}✓ Template: ${TEMPLATE}${NC}"
            return 0
        else
            echo -e "${RED}❌ Opción inválida.${NC}"
        fi
    done
}

validate_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${RED}❌ Sin conexión a internet. Verifica tu conexión.${NC}"
        return 1
    fi
    return 0
}

# Función genérica de validación interactiva
validate_input() {
    local prompt="$1"
    local variable_name="$2"
    local pattern="${3:-.+}"  # Por defecto acepta cualquier cosa no vacía
    local error_msg="${4:-Valor inválido}"
    local example="${5}"
    
    while true; do
        if [[ -n "$example" ]]; then
            read -p "$(echo -e "${YELLOW}${prompt}${NC} (ej: ${example}): ")" value
        else
            read -p "$(echo -e "${YELLOW}${prompt}${NC}: ")" value
        fi
        
        if [[ "$value" =~ $pattern ]]; then
            eval "$variable_name='$value'"
            break
        else
            echo -e "${RED}❌ $error_msg${NC}"
        fi
    done
}

detect_network_config() {
    # Detectar configuración de red del bridge usando /etc/network/interfaces
    local bridge_ip=""
    local bridge_netmask=""
    local bridge_gateway=""
    local bridge_cidr="24"  # Default
    
    # Buscar la configuración del bridge en /etc/network/interfaces
    if [[ -f /etc/network/interfaces ]]; then
        local in_bridge_section=0
        local line_buffer=""
        
        while IFS= read -r line; do
            # Si encontramos la sección del bridge
            if [[ "$line" =~ ^auto.*$BRIDGE|^iface.*$BRIDGE ]]; then
                in_bridge_section=1
            fi
            
            # Extraer IP
            if [[ $in_bridge_section -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*address[[:space:]] ]]; then
                bridge_ip=$(echo "$line" | awk '{print $2}')
            fi
            
            # Extraer netmask
            if [[ $in_bridge_section -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*netmask[[:space:]] ]]; then
                bridge_netmask=$(echo "$line" | awk '{print $2}')
            fi
            
            # Extraer gateway
            if [[ $in_bridge_section -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*gateway[[:space:]] ]]; then
                bridge_gateway=$(echo "$line" | awk '{print $2}')
            fi
            
            # Si salimos de la sección, detener búsqueda
            if [[ $in_bridge_section -eq 1 ]] && [[ "$line" =~ ^auto|^iface ]] && [[ ! "$line" =~ $BRIDGE ]]; then
                in_bridge_section=0
            fi
        done < /etc/network/interfaces
    fi
    
    # Convertir netmask a CIDR si se encontró
    if [[ -n "$bridge_netmask" ]]; then
        case "$bridge_netmask" in
            255.255.255.0) bridge_cidr="24" ;;
            255.255.255.128) bridge_cidr="25" ;;
            255.255.255.192) bridge_cidr="26" ;;
            255.255.255.224) bridge_cidr="27" ;;
            255.255.255.240) bridge_cidr="28" ;;
            255.255.255.248) bridge_cidr="29" ;;
            255.255.255.252) bridge_cidr="30" ;;
            255.255.0.0) bridge_cidr="16" ;;
            255.0.0.0) bridge_cidr="8" ;;
            *) bridge_cidr="24" ;;  # Default
        esac
    fi
    
    # Exportar variables detectadas
    DETECTED_BRIDGE_IP="$bridge_ip"
    DETECTED_BRIDGE_CIDR="$bridge_cidr"
    DETECTED_BRIDGE_GATEWAY="${bridge_gateway:-192.168.1.1}"  # Default si no se detecta
}

request_static_ip() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}CONFIGURACIÓN DE RED - IP ESTÁTICA${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Nginx Proxy Manager requiere una IP fija para funcionar correctamente${NC}"
    echo ""
    
    # Detectar configuración de red del bridge
    detect_network_config
    
    # Mostrar configuración detectada
    if [[ -n "$DETECTED_BRIDGE_IP" ]]; then
        echo -e "${CYAN}Configuración detectada del bridge ${BRIDGE}:${NC}"
        echo -e "  📡 Red: ${GREEN}${DETECTED_BRIDGE_IP}/${DETECTED_BRIDGE_CIDR}${NC}"
        echo -e "  🚪 Gateway: ${GREEN}${DETECTED_BRIDGE_GATEWAY}${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  No se pudo detectar la configuración de red automáticamente${NC}"
        echo -e "  Usando valores por defecto: 192.168.1.0/24, Gateway: 192.168.1.1${NC}"
        DETECTED_BRIDGE_CIDR="24"
        DETECTED_BRIDGE_GATEWAY="192.168.1.1"
        echo ""
    fi
    
    # Solo solicitar la IP del contenedor
    validate_input "IP del contenedor" "CONTAINER_IP" "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" "IP inválida. Usa formato 192.168.1.100" "192.168.1.100"
    
    # Usar configuración detectada
    CONTAINER_CIDR="$DETECTED_BRIDGE_CIDR"
    CONTAINER_GATEWAY="$DETECTED_BRIDGE_GATEWAY"
    
    echo -e "${GREEN}✓ IP Estática configurada: ${CONTAINER_IP}/${CONTAINER_CIDR}${NC}"
    echo -e "${GREEN}✓ Gateway: ${CONTAINER_GATEWAY}${NC}"
    echo ""
}

validate_vmid() {
    validate_input "VMID del contenedor" "CTID" "^[0-9]{3,5}$" "VMID inválido. Usa números entre 100-99999" "9000"
    # Verificar si ya existe
    if pct status $CTID &>/dev/null; then
        echo -e "${RED}❌ El VMID $CTID ya existe. Por favor usa otro.${NC}"
        validate_vmid  # Reintentar
    fi
}

get_current_node() {
    # Detectar el nodo actual donde se ejecuta el script
    local node
    if command -v hostname &> /dev/null; then
        node=$(hostname)
        echo "$node"
        return 0
    fi
    # Fallback para casos especiales
    echo "pve"
    return 0
}

generate_hostname() {
    # Generar nombre automático: Nginx-PMX
    echo "Nginx-PMX"
}

get_bridge() {
    # Detectar bridge principal disponible
    local bridge
    if grep -q "vmbr0" /proc/net/dev 2>/dev/null; then
        bridge="vmbr0"
    elif grep -q "vmbr1" /proc/net/dev 2>/dev/null; then
        bridge="vmbr1"
    else
        bridge="vmbr0"  # Por defecto
    fi
    echo "$bridge"
}

validate_hostname() {
    # Generar hostname automáticamente basado en VMID
    HOSTNAME=$(generate_hostname)
    echo -e "${GREEN}✓ Nombre del contenedor asignado automáticamente: ${HOSTNAME}${NC}"
}

validate_node() {
    # Detectar el nodo actual automáticamente
    NODE=$(get_current_node)
    echo -e "${GREEN}✓ Nodo detectado automáticamente: ${NODE}${NC}"
}

validate_storage() {
    echo -e "${YELLOW}Detectando almacenamientos disponibles para LXC...${NC}"
    
    # Obtener almacenamientos válidos desde pvesm status
    # Compatible con todas las versiones de Proxmox
    local STORAGES=$(pvesm status 2>/dev/null | tail -n +2 | awk '{print $1}' | head -5)
    
    if [[ -z "$STORAGES" ]]; then
        echo -e "${RED}❌ No se encontraron almacenamientos.${NC}"
        return 1
    fi
    
    local STORAGE_ARRAY=($STORAGES)
    
    if [[ ${#STORAGE_ARRAY[@]} -eq 1 ]]; then
        STORAGE="${STORAGE_ARRAY[0]}"
        echo -e "${GREEN}✓ Almacenamiento seleccionado automáticamente: ${STORAGE}${NC}"
        return 0
    fi
    
    # Si hay múltiples, permitir seleccionar
    echo -e "${CYAN}Almacenamientos disponibles:${NC}"
    local i=1
    for storage in "${STORAGE_ARRAY[@]}"; do
        echo "  [$i] $storage"
        ((i++))
    done
    
    while true; do
        read -p "$(echo -e "${YELLOW}Elige almacenamiento${NC}") (1-$((i-1))): " STORAGE_CHOICE
        
        if [[ "$STORAGE_CHOICE" =~ ^[0-9]+$ ]] && [[ $STORAGE_CHOICE -ge 1 ]] && [[ $STORAGE_CHOICE -lt $i ]]; then
            STORAGE="${STORAGE_ARRAY[$((STORAGE_CHOICE-1))]}"
            echo -e "${GREEN}✓ Almacenamiento: ${STORAGE}${NC}"
            break
        else
            echo -e "${RED}❌ Opción inválida.${NC}"
        fi
    done
    
    return 0
}

################################################################################
# SECCIÓN 6: FUNCIÓN PRINCIPAL DE INSTALACIÓN
################################################################################

install_npm() {
    log_message "Iniciando instalación NPM - Nivel: $PROFILE"
    
    validate_template || return 1
    validate_internet || return 1
    
    validate_vmid
    validate_hostname      # Ahora automático
    validate_node          # Ahora automático
    validate_storage || return 1
    
    # Bridge automático (por defecto vmbr0)
    BRIDGE=$(get_bridge)
    echo -e "${GREEN}✓ Bridge de red asignado automáticamente: ${BRIDGE}${NC}"
    
    # Solicitar configuración de IP estática
    request_static_ip
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}CREDENCIALES DE SEGURIDAD${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    read -sp "$(echo -e "${YELLOW}Contraseña ROOT para MariaDB${NC}") : " DB_ROOT_PASS
    echo ""
    read -sp "$(echo -e "${YELLOW}Contraseña NPM para la base de datos${NC}") : " DB_NPM_PASS
    echo ""
    
    # Mostrar resumen
    echo ""
    echo -e "$HEADER_TOP"
    echo -e "${CYAN}║${NC}  ${YELLOW}RESUMEN DE INSTALACIÓN${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  VMID: ${GREEN}$CTID${NC}          Hostname: ${GREEN}$HOSTNAME${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Nodo: ${GREEN}$NODE${NC}          Bridge: ${GREEN}$BRIDGE${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  RAM: ${GREEN}${RAM}MB${NC} | CPU: ${GREEN}${CPU}${NC} | Disco: ${GREEN}${DISK}GB${NC}      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  Perfil: ${GREEN}${PROFILE}${NC}    Template: ${GREEN}${TEMPLATE_STORAGE}${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  IP: ${GREEN}${CONTAINER_IP}/${CONTAINER_CIDR}${NC} | GW: ${GREEN}${CONTAINER_GATEWAY}${NC}         ${CYAN}║${NC}"
    echo -e "$HEADER_BOT"
    echo -e "${YELLOW}¿Confirmas? (s/n):${NC} "
    read CONFIRM
    
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
        echo -e "${YELLOW}Instalación cancelada - Volviendo al menú...${NC}"
        sleep 2
        return 1
    fi
    
    # Actualizar configuración con URLs
    load_config || true
    DOCKER_URL=${DOCKER_URL:-$DEFAULT_DOCKER_URL}
    COMPOSE_VERSION=${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}
    NPM_IMAGE=${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}
    DB_IMAGE=${DB_IMAGE:-$DEFAULT_DB_IMAGE}
    
    # Crear contenedor
    echo -e "${CYAN}Creando contenedor LXC...${NC}"
    echo -e "${YELLOW}Template Storage: ${TEMPLATE_STORAGE}${NC}"
    echo -e "${YELLOW}Template: ${TEMPLATE}${NC}"
    
    # TEMPLATE Storage detectado en validate_template()
    # El almacenamiento dinámico ($STORAGE) es solo para el rootfs
    # Si el template es un archivo direct (no indexado), usar ruta completa
    local template_source="$TEMPLATE_STORAGE:vztmpl/$TEMPLATE"
    if [[ "$TEMPLATE" == *.tar.zst ]]; then
        template_source="$TEMPLATE_STORAGE:vztmpl/$TEMPLATE"
    fi
    
    pct create $CTID "$template_source" \
        --cores $CPU \
        --memory $RAM \
        --swap 512 \
        --rootfs $STORAGE:$DISK \
        --net0 name=eth0,bridge=$BRIDGE,ip=${CONTAINER_IP}/${CONTAINER_CIDR},gw=${CONTAINER_GATEWAY} \
        --hostname $HOSTNAME \
        --password "$DB_ROOT_PASS" \
        --nameserver 8.8.8.8 \
        --searchdomain local \
        --unprivileged 0 \
        --features nesting=1
    
    pct start $CTID
    echo -e "${GREEN}✓ Contenedor iniciado${NC}"
    
    # Crear script de instalación en el HOST (evita problemas de heredoc)
    LOCAL_SCRIPT="/tmp/npm_install_$CTID.sh"
    CONTAINER_SCRIPT="/root/install_npm.sh"
    
    # Crear el script directamente en el host SIN usar pct exec
    cat > "$LOCAL_SCRIPT" << 'SCRIPT_END'
#!/bin/bash
# Recibir contraseñas como argumentos (evita problemas de expansión)
DB_NPM_PASS="$1"
DB_ROOT_PASS="$2"

set -e
export LANG=C.UTF-8 LC_ALL=C.UTF-8 DEBIAN_FRONTEND=noninteractive
apt update && apt upgrade -y
apt install -y curl ca-certificates gnupg lsb-release sudo vim net-tools jq procps iputils-ping wget netcat-openbsd
! command -v docker &>/dev/null && { curl -fsSL https://get.docker.com | sh; systemctl enable docker; systemctl start docker; }
mkdir -p /root/nginx-proxy-manager/{data/mysql,letsencrypt,backups}
cd /root/nginx-proxy-manager
docker network create npm_network 2>/dev/null || true

# Crear script de espera para conexión a BD
cat > /root/nginx-proxy-manager/wait-for-db.sh << 'WAITSCRIPT'
#!/bin/bash
set -e
host="$1"
port="$2"
shift 2
cmd="$@"

until nc -z "$host" "$port"; do
  >&2 echo "Base de datos en $host:$port aún no está lista - esperando..."
  sleep 2
done

>&2 echo "Base de datos lista - ejecutando comando..."
exec $cmd
WAITSCRIPT
chmod +x /root/nginx-proxy-manager/wait-for-db.sh

cat > docker-compose.yml << 'YAML_END'
networks:
  npm_net:
    external: true
    name: npm_network
services:
  npm_app:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm_app
    restart: unless-stopped
    networks: [npm_net]
    ports: ["80:80", "443:443", "81:81"]
    environment:
      TZ: 'America/Mexico_City'
      DB_MYSQL_HOST: 'npm_db'
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: npm
      DB_MYSQL_PASSWORD: 'NPMPASS_PLACEHOLDER'
      DB_MYSQL_NAME: 'npm'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      npm_db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:81/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
  npm_db:
    image: jc21/mariadb-aria:latest
    container_name: npm_db
    restart: unless-stopped
    networks: [npm_net]
    environment:
      MYSQL_ROOT_PASSWORD: 'ROOTPASS_PLACEHOLDER'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: npm
      MYSQL_PASSWORD: 'NPMPASS_PLACEHOLDER'
      MARIADB_AUTO_UPGRADE: '1'
    volumes:
      - ./data/mysql:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "127.0.0.1", "-u", "root", "-pROOTPASS_PLACEHOLDER"]
      interval: 10s
      timeout: 5s
      retries: 30
      start_period: 30s
YAML_END
sed -i "s|NPMPASS_PLACEHOLDER|${DB_NPM_PASS}|g;s|ROOTPASS_PLACEHOLDER|${DB_ROOT_PASS}|g" docker-compose.yml
docker compose up -d 2>&1 || { sleep 5; docker compose up -d; }

# Esperar a que MariaDB esté lista
echo "Esperando a que la base de datos esté lista..."
for i in {1..60}; do
  if docker exec npm_db mariadb-admin ping -h 127.0.0.1 -u root -p"${DB_ROOT_PASS}" &>/dev/null 2>&1; then
    echo "✓ Base de datos lista"
    break
  fi
  echo "Intento $i/60..."
  sleep 2
done

# Esperar a que Nginx Proxy Manager esté listo
echo "Esperando a que Nginx Proxy Manager esté listo..."
for i in {1..60}; do
  if docker exec npm_app curl -s http://localhost:81 > /dev/null 2>&1; then
    echo "✓ Nginx Proxy Manager listo"
    break
  fi
  echo "Intento $i/60..."
  sleep 2
done

# Configurar autologin automático para root
mkdir -p /etc/systemd/system/agetty@tty1.service.d
cat > /etc/systemd/system/agetty@tty1.service.d/override.conf << 'AUTOLOGIN_END'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I $TERM
AUTOLOGIN_END

# Crear script de bienvenida simple (sin emojis)
cat > /etc/profile.d/00-npm-welcome.sh << 'WELCOME_END'
#!/bin/bash
# Script de bienvenida de Nginx Proxy Manager
if [ "$TERM" != "dumb" ]; then
  clear
  echo "========================================="
  echo "Nginx Proxy Manager - LXC Container"
  echo "========================================="
  echo ""
  echo "System: $(lsb_release -ds)"
  echo "Hostname: $(hostname)"
  echo "IP Address: $(hostname -I 2>/dev/null | awk '{print $1}')"
  echo ""
  echo "Created by: 3KNOX"
  echo "GitHub: https://github.com/3KNOX"
  echo ""
  docker ps 2>/dev/null && echo "" || true
fi
WELCOME_END
chmod 755 /etc/profile.d/00-npm-welcome.sh

# Crear MOTD simple sin caracteres especiales
cat > /etc/motd << 'MOTD_END'
==========================================
Nginx Proxy Manager - LXC Container
==========================================

Web Interface: http://localhost:81
User: admin@example.com
Password: changeme

Provided by: 3KNOX
https://github.com/3KNOX
==========================================
MOTD_END
SCRIPT_END

    chmod +x "$LOCAL_SCRIPT"
    
    # Copiar y ejecutar CON ARGUMENTOS (contraseñas)
    pct push $CTID "$LOCAL_SCRIPT" "$CONTAINER_SCRIPT"
    pct exec $CTID -- bash "$CONTAINER_SCRIPT" "$DB_NPM_PASS" "$DB_ROOT_PASS"
    
    # Limpiar archivo temporal
    rm -f "$LOCAL_SCRIPT"
    
    # Detectar IP con reintentos
    echo -e "${YELLOW}Detectando IP del contenedor...${NC}"
    CONTAINER_IP=""
    for i in {1..30}; do
        CONTAINER_IP=$(pct exec $CTID -- hostname -I 2>/dev/null | awk '{print $1}' || echo "")
        if [[ ! -z "$CONTAINER_IP" && "$CONTAINER_IP" != "" ]]; then
            echo -e "${GREEN}✓ IP detectada: $CONTAINER_IP${NC}"
            break
        else
            echo -n "."
            sleep 1
        fi
    done
    echo ""
    
    if [[ -z "$CONTAINER_IP" ]]; then
        echo -e "${RED}❌ No se pudo detectar IP${NC}"
        return 1
    fi
    
    # Guardar configuración
    save_config
    
    # Resumen
    echo ""
    echo -e "${GREEN}$HEADER_TOP${NC}"
    echo -e "${GREEN}║${NC}     ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅            ${GREEN}║${NC}"
    echo -e "${GREEN}$HEADER_BOT${NC}"
    echo ""
    echo -e "$MENU_TOP"
    echo -e "  ${CYAN}INFORMACIÓN DE ACCESO${NC}"
    echo -e "  🌐 URL: ${GREEN}http://${CONTAINER_IP}:81${NC}"
    echo -e "  👤 Usuario: ${GREEN}admin@example.com${NC}"
    echo -e "  🔑 Contraseña: ${GREEN}changeme${NC}"
    echo -e ""
    echo -e "  ${CYAN}DETALLES DEL CONTENEDOR${NC}"
    echo -e "  📌 VMID: ${GREEN}${CTID}${NC}       📍 Hostname: ${GREEN}${HOSTNAME}${NC}"
    echo -e "  🖧 IP: ${GREEN}${CONTAINER_IP}${NC}        ⚙️  Perfil: ${GREEN}${PROFILE}${NC}"
    echo -e "$MENU_BOT"
    echo ""
    
    log_message "Instalación completada - VMID: $CTID, IP: $CONTAINER_IP"
    read -p "Presiona Enter para volver al menú..."
}

################################################################################
# SECCIÓN 6B: FUNCIÓN REINSTALAR
################################################################################

reinstall_npm() {
    show_header
    
    load_config || {
        echo -e "${RED}❌ No hay configuración guardada${NC}"
        echo -e "${YELLOW}ℹ️  Primero instala un contenedor con [1], [2] o [3]${NC}"
        sleep 2
        return
    }
    
    echo -e "$MENU_TOP"
    echo -e "  🔄 REINSTALAR CONTENEDOR"
    echo -e "$MENU_BOT"
    echo ""
    
    echo -e "${YELLOW}⚠️  ADVERTENCIA:${NC}"
    echo -e "  Este proceso va a:"
    echo -e "  1. Destruir el contenedor VMID $LAST_VMID (${LAST_HOSTNAME})"
    echo -e "  2. Recrearlo desde cero manteniendo la configuración"
    echo -e "  3. Reinstalar Docker, imágenes y servicios"
    echo ""
    
    read -p "¿Estás seguro? (s/n): " confirm
    [[ "$confirm" != "s" ]] && return
    echo ""
    
    echo -e "${YELLOW}Destruyendo contenedor...${NC}"
    if pct destroy "$LAST_VMID" 2>&1; then
        echo -e "${GREEN}✓ Contenedor destruido${NC}"
    else
        echo -e "${RED}❌ Error al destruir contenedor${NC}"
        sleep 2
        return 1
    fi
    
    sleep 2
    
    echo -e "${YELLOW}Recreando contenedor con la misma configuración...${NC}"
    CTID="$LAST_VMID"
    HOSTNAME="$LAST_HOSTNAME"
    NODE="$LAST_NODE"
    STORAGE="$LAST_STORAGE"
    BRIDGE="$LAST_BRIDGE"
    
    # Reconfigurar RAM/CPU/DISK según perfil
    case "$LAST_PROFILE" in
        *NORMAL*) RAM=512; CPU=1; DISK=10; BACKUP="no" ;;
        *MEDIA*) RAM=1024; CPU=2; DISK=15; BACKUP="no" ;;
        *EXCELENTE*) RAM=2048; CPU=2; DISK=20; BACKUP="si" ;;
    esac
    
    PROFILE="$LAST_PROFILE"
    
    # Ejecutar instalación
    install_npm
}

################################################################################
# SECCIÓN 6C: FUNCIÓN ACTUALIZAR
################################################################################

update_npm() {
    show_header
    
    load_config || {
        echo -e "${RED}❌ No hay configuración guardada${NC}"
        echo -e "${YELLOW}ℹ️  Primero instala un contenedor con [1], [2] o [3]${NC}"
        sleep 2
        return
    }
    
    echo -e "$MENU_TOP"
    echo -e "  ⬆️  ACTUALIZAR SISTEMA Y SERVICIOS"
    echo -e "$MENU_BOT"
    echo ""
    
    if ! pct exec $LAST_VMID -- hostname &>/dev/null; then
        echo -e "${RED}❌ Contenedor VMID $LAST_VMID no responde${NC}"
        sleep 2
        return 1
    fi
    
    echo -e "${YELLOW}Containers actualizado:${NC}"
    echo -e "  📌 VMID: ${GREEN}${LAST_VMID}${NC}"
    echo -e "  🏠 Hostname: ${GREEN}${LAST_HOSTNAME}${NC}"
    echo ""
    
    read -p "¿Actualizar sistema + Docker + imágenes? (s/n): " confirm
    [[ "$confirm" != "s" ]] && return
    echo ""
    
    echo -e "${YELLOW}1. Actualizando sistema Debian...${NC}"
    if pct exec $LAST_VMID -- bash -c "apt update && apt upgrade -y" &>/dev/null; then
        echo -e "${GREEN}✓ Sistema actualizado${NC}"
    else
        echo -e "${RED}❌ Error en actualización de sistema${NC}"
    fi
    
    sleep 1
    
    echo -e "${YELLOW}2. Actualizando imágenes Docker...${NC}"
    if pct exec $LAST_VMID -- bash -c "docker pull jc21/nginx-proxy-manager:latest && docker pull jc21/mariadb-aria:latest" &>/dev/null; then
        echo -e "${GREEN}✓ Imágenes actualizadas${NC}"
    else
        echo -e "${RED}❌ Error al actualizar imágenes${NC}"
    fi
    
    sleep 1
    
    echo -e "${YELLOW}3. Reiniciando servicios...${NC}"
    if pct exec $LAST_VMID -- bash -c "cd /root/nginx-proxy-manager && docker compose up -d" &>/dev/null; then
        echo -e "${GREEN}✓ Servicios reiniciados${NC}"
    else
        echo -e "${RED}❌ Error al reiniciar servicios${NC}"
    fi
    
    sleep 2
    
    echo ""
    echo -e "${GREEN}✅ ACTUALIZACIÓN COMPLETADA${NC}"
    echo ""
    
    # Mostrar status
    echo -e "${CYAN}Estado de contenedores:${NC}"
    pct exec $LAST_VMID -- docker ps
    
    echo ""
    read -p "Presiona Enter para volver al menú..."
}

################################################################################
# SECCIÓN 7: LAZO PRINCIPAL
################################################################################

while true; do
    show_main_menu
    
    case "${MAIN_OPTION}" in
        1)
            RAM=512; CPU=1; DISK=10; BACKUP="no"; PROFILE="🟢 NORMAL"
            echo -e "${GREEN}✓ Configuración seleccionada: ${PROFILE}${NC}" && sleep 1 && install_npm
            ;;
        2)
            RAM=1024; CPU=2; DISK=15; BACKUP="no"; PROFILE="🟡 MEDIA"
            echo -e "${GREEN}✓ Configuración seleccionada: ${PROFILE}${NC}" && sleep 1 && install_npm
            ;;
        3)
            RAM=2048; CPU=2; DISK=20; BACKUP="si"; PROFILE="🔵 EXCELENTE"
            echo -e "${GREEN}✓ Configuración seleccionada: ${PROFILE}${NC}" && sleep 1 && install_npm
            ;;
        4)
            reinstall_npm
            ;;
        5)
            update_npm
            ;;
        0)
            echo -e "${YELLOW}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción inválida (0-5)${NC}"
            sleep 1
            ;;
    esac
done


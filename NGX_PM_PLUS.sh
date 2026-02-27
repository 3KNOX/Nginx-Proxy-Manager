#!/bin/bash
###############################################################################
# NGINX PROXY MANAGER - PROXMOX INSTALLER v2.0
# Autor: 3KNOX
# Descripción: Instalador completo con menú, gestión de config, actualización
###############################################################################

set -e

# ================ COLORES Y CONSTANTES ================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

CONFIG_FILE="/root/.npm_config"
LOG_FILE="/root/npm_installer.log"
SCRIPT_VERSION="2.0"

# Valores por defecto de URLs
DEFAULT_DOCKER_URL="https://get.docker.com"
DEFAULT_COMPOSE_VERSION="2.20.0"
DEFAULT_NPM_IMAGE="jc21/nginx-proxy-manager:latest"
DEFAULT_DB_IMAGE="jc21/mariadb-aria:latest"

# ================ FUNCIONES AUXILIARES ================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}     🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER 🚀         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                        v${SCRIPT_VERSION}                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              Created by: ${GREEN}3KNOX${CYAN}                        ║${NC}"
    echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ================ GESTIÓN DE CONFIGURACIÓN ================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        echo -e "${GREEN}✓ Configuración cargada${NC}"
        return 0
    else
        return 1
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Configuración de NPM Installer - $(date)
LAST_VMID=$CTID
LAST_HOSTNAME=$HOSTNAME
LAST_NODE=$NODE
LAST_BRIDGE=$BRIDGE
LAST_PROFILE=$PROFILE
LAST_CPU=$CPU
LAST_RAM=$RAM
LAST_DISK=$DISK
LAST_BACKUP=$BACKUP

# URLs configurables
DOCKER_URL=${DOCKER_URL:-$DEFAULT_DOCKER_URL}
COMPOSE_VERSION=${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}
NPM_IMAGE=${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}
DB_IMAGE=${DB_IMAGE:-$DEFAULT_DB_IMAGE}
EOF
    log_message "Configuración guardada en $CONFIG_FILE"
}

show_config() {
    show_header
    echo -e "${YELLOW}┌─ CONFIGURACIÓN GUARDADA ─────────────────────────────────┐${NC}"
    echo ""
    
    if load_config; then
        echo -e "  ${CYAN}DATOS DEL CONTENEDOR:${NC}"
        echo -e "    📌 VMID: ${GREEN}${LAST_VMID:-No guardado}${NC}"
        echo -e "    📍 Hostname: ${GREEN}${LAST_HOSTNAME:-No guardado}${NC}"
        echo -e "    🖧 Nodo: ${GREEN}${LAST_NODE:-No guardado}${NC}"
        echo -e "    🌉 Bridge: ${GREEN}${LAST_BRIDGE:-No guardado}${NC}"
        echo -e "    ⚙️  Perfil: ${GREEN}${LAST_PROFILE:-No guardado}${NC}"
        echo ""
        echo -e "  ${CYAN}URLs CONFIGURADAS:${NC}"
        echo -e "    🔗 Docker: ${GREEN}${DOCKER_URL}${NC}"
        echo -e "    🔗 Compose: ${GREEN}${COMPOSE_VERSION}${NC}"
        echo -e "    🐳 Imagen NPM: ${GREEN}${NPM_IMAGE}${NC}"
        echo -e "    📦 Imagen BD: ${GREEN}${DB_IMAGE}${NC}"
    else
        echo -e "  ${YELLOW}⚠️  No hay configuración guardada aún${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p "Presiona Enter para volver..."
}

# ================ EDITOR DE URLs ================

edit_urls() {
    show_header
    echo -e "${YELLOW}┌─ EDITAR URLs ────────────────────────────────────────────┐${NC}"
    echo ""
    
    load_config || true
    
    echo -e "  ${CYAN}URL actual Docker:${NC} ${GREEN}${DOCKER_URL:-$DEFAULT_DOCKER_URL}${NC}"
    read -p "  Nueva URL Docker (Enter para mantener): " NEW_DOCKER_URL
    [[ ! -z "$NEW_DOCKER_URL" ]] && DOCKER_URL="$NEW_DOCKER_URL" || DOCKER_URL="${DOCKER_URL:-$DEFAULT_DOCKER_URL}"
    
    echo ""
    echo -e "  ${CYAN}Versión actual Compose:${NC} ${GREEN}${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}${NC}"
    read -p "  Nueva versión (Enter para mantener): " NEW_COMPOSE_VERSION
    [[ ! -z "$NEW_COMPOSE_VERSION" ]] && COMPOSE_VERSION="$NEW_COMPOSE_VERSION" || COMPOSE_VERSION="${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}"
    
    echo ""
    echo -e "  ${CYAN}Imagen NPM actual:${NC} ${GREEN}${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}${NC}"
    read -p "  Nueva imagen (Enter para mantener): " NEW_NPM_IMAGE
    [[ ! -z "$NEW_NPM_IMAGE" ]] && NPM_IMAGE="$NEW_NPM_IMAGE" || NPM_IMAGE="${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}"
    
    echo ""
    echo -e "  ${CYAN}Imagen BD actual:${NC} ${GREEN}${DB_IMAGE:-$DEFAULT_DB_IMAGE}${NC}"
    read -p "  Nueva imagen (Enter para mantener): " NEW_DB_IMAGE
    [[ ! -z "$NEW_DB_IMAGE" ]] && DB_IMAGE="$NEW_DB_IMAGE" || DB_IMAGE="${DB_IMAGE:-$DEFAULT_DB_IMAGE}"
    
    save_config
    
    echo ""
    echo -e "${GREEN}✓ URLs actualizadas correctamente${NC}"
    sleep 2
}

# ================ VALIDACIONES ================

validate_template() {
    if ! ls /var/lib/vz/template/cache/debian-13-standard* &>/dev/null; then
        echo -e "${RED}❌ Template Debian 13 no encontrada.${NC}"
        echo -e "${YELLOW}Descárgala con: pveam update && pveam download local debian-13-standard_13.0-1_amd64.tar.gz${NC}"
        return 1
    fi
    return 0
}

validate_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        echo -e "${RED}❌ Sin conexión a internet. Verifica tu conexión.${NC}"
        return 1
    fi
    return 0
}

validate_vmid() {
    while true; do
        read -p "$(echo -e ${YELLOW}VMID del contenedor${NC}) (ej: 9000): " CTID
        if [[ "$CTID" =~ ^[0-9]{3,5}$ ]]; then
            if pct status $CTID &>/dev/null; then
                echo -e "${RED}❌ El VMID $CTID ya existe. Por favor usa otro.${NC}"
            else
                break
            fi
        else
            echo -e "${RED}❌ VMID inválido. Usa números entre 100-99999.${NC}"
        fi
    done
}

validate_hostname() {
    while true; do
        read -p "$(echo -e ${YELLOW}Nombre del contenedor${NC}) (hostname, ej: npm-prod): " HOSTNAME
        if [[ -z "$HOSTNAME" ]]; then
            echo -e "${RED}❌ El hostname no puede estar vacío.${NC}"
        else
            break
        fi
    done
}

validate_node() {
    while true; do
        read -p "$(echo -e ${YELLOW}Nodo de Proxmox${NC}) (ej: pve): " NODE
        if [[ -z "$NODE" ]]; then
            echo -e "${RED}❌ El nodo no puede estar vacío.${NC}"
        else
            break
        fi
    done
}

# ================ MENÚ PRINCIPAL ================

show_main_menu() {
    show_header
    echo -e "${BLUE}┌─ MENÚ PRINCIPAL ──────────────────────────────────────────┐${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} 🟢 INSTALAR - Nivel NORMAL"
    echo -e "  ${YELLOW}[2]${NC} 🟡 INSTALAR - Nivel MEDIA"
    echo -e "  ${BLUE}[3]${NC} 🔵 INSTALAR - Nivel EXCELENTE"
    echo ""
    echo -e "  ${CYAN}[4]${NC} 🔄 REINSTALAR - Mantener datos"
    echo -e "  ${CYAN}[5]${NC} ⬆️  ACTUALIZAR - Dependencias"
    echo -e "  ${CYAN}[6]${NC} 🌐 EDITAR URLs - Cambiar links"
    echo -e "  ${CYAN}[7]${NC} 📋 VER CONFIG - Mostrar guardada"
    echo ""
    echo -e "  ${RED}[0]${NC} ❌ SALIR"
    echo ""
    echo -e "${BLUE}└──────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}Elige opción${NC}) (0-7): " MAIN_OPTION
}

# ================ INSTALAR ================

install_npm() {
    log_message "Iniciando instalación NPM - Nivel: $PROFILE"
    
    validate_template || return 1
    validate_internet || return 1
    
    validate_vmid
    validate_hostname
    validate_node
    
    read -p "$(echo -e ${YELLOW}Bridge de red${NC}) (default vmbr0): " BRIDGE
    BRIDGE=${BRIDGE:-vmbr0}
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}CREDENCIALES DE SEGURIDAD${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    read -sp "$(echo -e ${YELLOW}Contraseña ROOT para MariaDB${NC}): " DB_ROOT_PASS
    echo ""
    read -p "$(echo -e ${YELLOW}Usuario NPM para base de datos${NC}) (default: npm): " DB_NPM_USER
    DB_NPM_USER=${DB_NPM_USER:-npm}
    read -sp "$(echo -e ${YELLOW}Contraseña NPM para la base de datos${NC}): " DB_NPM_PASS
    echo ""
    
    # Mostrar resumen
    echo ""
    echo -e "${CYAN}╔════ RESUMEN DE INSTALACIÓN ════╗${NC}"
    echo -e "  VMID: ${GREEN}$CTID${NC}"
    echo -e "  Hostname: ${GREEN}$HOSTNAME${NC}"
    echo -e "  Nodo: ${GREEN}$NODE${NC}"
    echo -e "  Bridge: ${GREEN}$BRIDGE${NC}"
    echo -e "  Perfil: ${GREEN}$PROFILE${NC}"
    echo -e "  RAM: ${GREEN}${RAM}MB${NC} | CPU: ${GREEN}${CPU}${NC} | Disco: ${GREEN}${DISK}GB${NC}"
    echo -e "${CYAN}════════════════════════════════${NC}"
    echo ""
    read -p "¿Confirmas? (s/n): " CONFIRM
    
    if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
        echo -e "${YELLOW}Instalación cancelada.${NC}"
        return 1
    fi
    
    # Actualizar configuración con URLs
    load_config || true
    DOCKER_URL=${DOCKER_URL:-$DEFAULT_DOCKER_URL}
    COMPOSE_VERSION=${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}
    NPM_IMAGE=${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}
    DB_IMAGE=${DB_IMAGE:-$DEFAULT_DB_IMAGE}
    
    # Crear contenedor
    echo -e "${CYAN}Creando contenedor LXC Debian 13...${NC}"
    TEMPLATE="local:vztmpl/debian-13-standard_13.0-1_amd64.tar.gz"
    
    pct create $CTID $TEMPLATE \
        --cores $CPU \
        --memory $RAM \
        --swap 512 \
        --rootfs local:$DISK \
        --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
        --hostname $HOSTNAME \
        --password "$DB_ROOT_PASS" \
        --nameserver 8.8.8.8 \
        --searchdomain local \
        --unprivileged 0
    
    pct start $CTID
    echo -e "${GREEN}✓ Contenedor iniciado${NC}"
    
    # Script de instalación
    INSTALL_SCRIPT="/root/install_npm.sh"
    
    # Escapar contraseñas
    ROOT_PASS_ESCAPED=$(printf '%s' "$DB_ROOT_PASS" | sed "s/'/\\\\\\\\'/g" | sed 's/\\/\\\\\\\\\\\\/g')
    NPM_PASS_ESCAPED=$(printf '%s' "$DB_NPM_PASS" | sed "s/'/\\\\\\\\'/g" | sed 's/\\/\\\\\\\\\\\\/g')
    
    pct exec $CTID -- bash -c "cat <<'EOF' > $INSTALL_SCRIPT
#!/bin/bash
set -e

echo 'Actualizando sistema...'
apt update && apt upgrade -y
apt install -y curl ca-certificates gnupg lsb-release sudo vim net-tools jq apt-transport-https software-properties-common procps iputils-ping

echo 'Instalando Docker...'
if ! command -v docker &> /dev/null; then
  curl -fsSL $DOCKER_URL -o get-docker.sh
  chmod +x get-docker.sh
  sh get-docker.sh
  systemctl enable docker
  systemctl start docker
fi

echo 'Instalando Docker Compose...'
if ! command -v docker-compose &> /dev/null; then
  COMPOSE_VERSION=$COMPOSE_VERSION
  curl -L https://github.com/docker/compose/releases/download/v\${COMPOSE_VERSION}/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose 2>/dev/null || {
    curl -L https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose
  }
  chmod +x /usr/local/bin/docker-compose
fi

NPM_ROOT=/root/nginx-proxy-manager
mkdir -p \$NPM_ROOT/{data/mysql,letsencrypt,backups}
cd \$NPM_ROOT

DOCKER_NET=npm_network
docker network create \$DOCKER_NET 2>/dev/null || true

cat <<'COMPOSE' > docker-compose.yml
version: '3.8'

networks:
  npm_net:
    external: true
    name: npm_network

services:
  npm_app:
    image: $NPM_IMAGE
    container_name: npm_app
    restart: unless-stopped
    networks:
      - npm_net
    ports:
      - \"80:80\"
      - \"443:443\"
      - \"81:81\"
    environment:
      TZ: 'America/Mexico_City'
      DB_MYSQL_HOST: 'npm_db'
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: npm
      DB_MYSQL_PASSWORD: '${NPM_PASS_ESCAPED}'
      DB_MYSQL_NAME: 'npm'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - npm_db
    healthcheck:
      test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:81\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  npm_db:
    image: $DB_IMAGE
    container_name: npm_db
    restart: unless-stopped
    networks:
      - npm_net
    environment:
      MYSQL_ROOT_PASSWORD: '${ROOT_PASS_ESCAPED}'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: npm
      MYSQL_PASSWORD: '${NPM_PASS_ESCAPED}'
      MARIADB_AUTO_UPGRADE: '1'
    volumes:
      - ./data/mysql:/var/lib/mysql
    healthcheck:
      test: [\"CMD\", \"mariadb-admin\", \"ping\", \"-h\", \"127.0.0.1\"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
COMPOSE

echo 'Levantando contenedores con reintentos...'
for i in {1..3}; do
  if docker-compose up -d; then
    echo 'Contenedores levantados exitosamente'
    break
  else
    echo \"Reintento \$i/3...\"
    sleep 5
  fi
done

if [ \"$BACKUP\" == \"si\" ]; then
  cat <<'BCK' > backup_npm.sh
#!/bin/bash
BACKUP_DIR=/root/nginx-proxy-manager/backups
mkdir -p \$BACKUP_DIR
TIMESTAMP=\$(date +\"%Y%m%d_%H%M%S\")
docker exec npm_db /usr/bin/mysqldump -u root -p'${ROOT_PASS_ESCAPED}' npm > \"\$BACKUP_DIR/npm_db_\$TIMESTAMP.sql\"
tar -czf \"\$BACKUP_DIR/npm_data_\$TIMESTAMP.tar.gz\" -C /root/nginx-proxy-manager data
echo \"Backup completado: \$TIMESTAMP\"
BCK
  chmod +x backup_npm.sh
fi
EOF"
    
    pct exec $CTID -- bash $INSTALL_SCRIPT
    
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
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}            ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅     ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}┌─ INFORMACIÓN DE ACCESO ───────────────────────────────────┐${NC}"
    echo -e "  🌐 URL: ${GREEN}http://${CONTAINER_IP}:81${NC}"
    echo -e "  👤 Usuario: ${GREEN}admin@example.com${NC}"
    echo -e "  🔑 Contraseña: ${GREEN}changeme${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${CYAN}┌─ DETALLES DEL CONTENEDOR ─────────────────────────────────┐${NC}"
    echo -e "  📌 VMID: ${GREEN}${CTID}${NC}"
    echo -e "  📍 Hostname: ${GREEN}${HOSTNAME}${NC}"
    echo -e "  🖧 IP: ${GREEN}${CONTAINER_IP}${NC}"
    echo -e "  ⚙️  Perfil: ${GREEN}${PROFILE}${NC}"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    log_message "Instalación completada - VMID: $CTID, IP: $CONTAINER_IP"
    read -p "Presiona Enter para volver al menú..."
}

# ================ LAZO PRINCIPAL ================

while true; do
    show_main_menu
    
    case "$MAIN_OPTION" in
        1)
            show_header
            RAM=512
            CPU=1
            DISK=10
            BACKUP="no"
            PROFILE="🟢 NORMAL"
            echo -e "${GREEN}✓ Configuración seleccionada:${NC} ${PROFILE}"
            install_npm
            ;;
        2)
            show_header
            RAM=1024
            CPU=2
            DISK=15
            BACKUP="no"
            PROFILE="🟡 MEDIA"
            echo -e "${GREEN}✓ Configuración seleccionada:${NC} ${PROFILE}"
            install_npm
            ;;
        3)
            show_header
            RAM=2048
            CPU=2
            DISK=20
            BACKUP="si"
            PROFILE="🔵 EXCELENTE"
            echo -e "${GREEN}✓ Configuración seleccionada:${NC} ${PROFILE}"
            install_npm
            ;;
        4)
            echo -e "${YELLOW}Función de reinstalación...${NC}"
            echo -e "${YELLOW}⚠️  Próximamente - Contacta al soporte${NC}"
            sleep 2
            ;;
        5)
            echo -e "${YELLOW}Función de actualización...${NC}"
            echo -e "${YELLOW}⚠️  Próximamente - Contacta al soporte${NC}"
            sleep 2
            ;;
        6)
            edit_urls
            ;;
        7)
            show_config
            ;;
        0)
            echo -e "${YELLOW}Saliendo...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción inválida${NC}"
            sleep 1
            ;;
    esac
done


#!/bin/bash
set -e

# ---------------- COLORES ----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER 🚀         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}              Created by: ${GREEN}3KNOX${CYAN}                        ║${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Función para validar entrada del menú
validate_menu() {
    while true; do
        echo -e "${YELLOW}┌─ CONFIGURACIÓN DE RECURSOS ─────────────────────────────┐${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} 🟢 NORMAL - ${CYAN}Aplicaciones ligeras${NC}"
        echo "      └─ RAM: 512 MB  | CPU: 1 core  | Disco: 10GB"
        echo ""
        echo -e "  ${YELLOW}[2]${NC} 🟡 MEDIA - ${CYAN}Producción estándar${NC}"
        echo "      └─ RAM: 1024 MB | CPU: 2 cores | Disco: 15GB"
        echo ""
        echo -e "  ${GREEN}[3]${NC} 🔵 EXCELENTE - ${CYAN}Producción crítica${NC}"
        echo "      └─ RAM: 2048 MB | CPU: 2 cores | Disco: 20GB + Backups ✓"
        echo ""
        echo -e "${YELLOW}└────────────────────────────────────────────────────────${NC}"
        echo ""
        read -p "$(echo -e ${GREEN}Elige opción${NC}) (1-3): " OPT_LEVEL
        
        if [[ "$OPT_LEVEL" =~ ^[1-3]$ ]]; then
            break
        else
            echo -e "${RED}❌ Opción inválida. Por favor elige 1, 2 o 3.${NC}"
            echo ""
            sleep 2
            clear
        fi
    done
}

validate_menu

case "$OPT_LEVEL" in
  1)
    RAM=512
    CPU=1
    DISK=10
    BACKUP="no"
    PROFILE="🟢 NORMAL"
    ;;
  2)
    RAM=1024
    CPU=2
    DISK=15
    BACKUP="no"
    PROFILE="🟡 MEDIA"
    ;;
  3)
    RAM=2048
    CPU=2
    DISK=20
    BACKUP="si"
    PROFILE="🔵 EXCELENTE"
    ;;
  *)
    echo -e "${RED}❌ Opción no válida. Saliendo...${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}✓ Configuración seleccionada:${NC} ${PROFILE}"
echo -e "  RAM: ${GREEN}${RAM}MB${NC} | CPU: ${GREEN}${CPU}${NC} | Disco: ${GREEN}${DISK}GB${NC} | Backups: ${GREEN}${BACKUP}${NC}"
echo ""

# Función para validar entrada de VMID
validate_vmid() {
    while true; do
        read -p "$(echo -e ${YELLOW}VMID del contenedor${NC}) (ej: 9000): " CTID
        if [[ "$CTID" =~ ^[0-9]{3,5}$ ]]; then
            break
        else
            echo -e "${RED}❌ VMID inválido. Usa números entre 100-99999.${NC}"
        fi
    done
}

echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}DATOS DEL CONTENEDOR${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

validate_vmid
read -p "$(echo -e ${YELLOW}Nombre del contenedor${NC}) (hostname, ej: npm-prod): " HOSTNAME
read -p "$(echo -e ${YELLOW}Nodo de Proxmox${NC}) (ej: pve): " NODE
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
echo ""

# ---------------- CREAR CONTENEDOR DEBIAN 13 ----------------
TEMPLATE="local:vztmpl/debian-13-standard_13.0-1_amd64.tar.gz"
echo -e "${CYAN}Creando contenedor LXC Debian 13...${NC}"
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
echo -e "${GREEN}Contenedor $CTID iniciado.${NC}"

# ---------------- SCRIPT DE INSTALACIÓN DENTRO DEL CONTENEDOR ----------------
INSTALL_SCRIPT="/root/install_npm.sh"
pct exec $CTID -- bash -c "cat <<'EOF' > $INSTALL_SCRIPT
#!/bin/bash
set -e

# Actualizar sistema
apt update && apt upgrade -y
apt install -y curl ca-certificates gnupg lsb-release sudo vim net-tools lsb-release

# Instalar Docker
if ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  chmod +x get-docker.sh
  sh get-docker.sh
  systemctl enable docker
fi

# Instalar Docker Compose
if ! command -v docker-compose &> /dev/null; then
  COMPOSE_LATEST=\$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest | grep '\"tag_name\":' | cut -d '\"' -f 4)
  curl -L https://github.com/docker/compose/releases/download/\${COMPOSE_LATEST}/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# Directorios
NPM_ROOT=/root/nginx-proxy-manager
mkdir -p \$NPM_ROOT/data/mysql
mkdir -p \$NPM_ROOT/letsencrypt
mkdir -p \$NPM_ROOT/backups
cd \$NPM_ROOT

# Red Docker
DOCKER_NET=npm_network
if ! docker network ls | grep -q \$DOCKER_NET; then
  docker network create \$DOCKER_NET
fi

# Docker-compose
cat <<EOD > docker-compose.yml
version: '3.8'

networks:
  npm_net:
    external: \$DOCKER_NET

services:
  npm_app:
    image: jc21/nginx-proxy-manager:latest
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
      DB_MYSQL_USER: '$DB_NPM_USER'
      DB_MYSQL_PASSWORD: '$DB_NPM_PASS'
      DB_MYSQL_NAME: 'npm'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - npm_db

  npm_db:
    image: jc21/mariadb-aria:latest
    container_name: npm_db
    restart: unless-stopped
    networks:
      - npm_net
    environment:
      MYSQL_ROOT_PASSWORD: '$DB_ROOT_PASS'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: '$DB_NPM_USER'
      MYSQL_PASSWORD: '$DB_NPM_PASS'
      MARIADB_AUTO_UPGRADE: '1'
    volumes:
      - ./data/mysql:/var/lib/mysql
EOD

# Levantar contenedores
docker-compose up -d

# Backups automáticos si optado
if [ \"$BACKUP\" == \"si\" ]; then
cat <<'BCK' > backup_npm.sh
#!/bin/bash
BACKUP_DIR=/root/nginx-proxy-manager/backups
mkdir -p \$BACKUP_DIR
TIMESTAMP=\$(date +\"%Y%m%d_%H%M%S\")
docker exec npm_db /usr/bin/mysqldump -u root -p'$DB_ROOT_PASS' npm > \"\$BACKUP_DIR/npm_db_\$TIMESTAMP.sql\"
tar -czf \"\$BACKUP_DIR/npm_data_\$TIMESTAMP.tar.gz\" -C /root/nginx-proxy-manager data
echo \"Backup completado: \$BACKUP_DIR/npm_db_\$TIMESTAMP.sql y datos\"
BCK
chmod +x backup_npm.sh
fi
EOF"

pct exec $CTID -- bash $INSTALL_SCRIPT

# Detectar IP del contenedor
echo -e "${YELLOW}Detectando IP del contenedor...${NC}"
sleep 3
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

# Resumen final con diseño mejorado
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}                                                            ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}            ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅       ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}                                                            ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}┌─ INFORMACIÓN DE ACCESO ──────────────────────────────────┐${NC}"
echo -e "  🌐 ${CYAN}URL${NC}: ${GREEN}http://${CONTAINER_IP}:81${NC}"
echo -e "  👤 ${CYAN}Usuario${NC}: ${GREEN}admin@example.com${NC}"
echo -e "  🔑 ${CYAN}Contraseña${NC}: ${GREEN}changeme${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "${CYAN}┌─ DETALLES DEL CONTENEDOR ────────────────────────────────┐${NC}"
echo -e "  📌 ${CYAN}VMID${NC}: ${GREEN}${CTID}${NC}"
echo -e "  📍 ${CYAN}Hostname${NC}: ${GREEN}${HOSTNAME}${NC}"
echo -e "  🖧 ${CYAN}IP Address${NC}: ${GREEN}${CONTAINER_IP}${NC}"
echo -e "  ⚙️  ${CYAN}Configuración${NC}: ${GREEN}${PROFILE}${NC}"
echo -e "${CYAN}└──────────────────────────────────────────────────────────${NC}"
echo ""
if [[ "$BACKUP" == "si" ]]; then
  echo -e "${YELLOW}┌─ BACKUPS AUTOMÁTICOS ────────────────────────────────────┐${NC}"
  echo -e "  💾 Backups disponibles en:"
  echo -e "     ${GREEN}/root/nginx-proxy-manager/backups${NC}"
  echo -e "${YELLOW}└──────────────────────────────────────────────────────────${NC}"
  echo ""
fi
echo -e "${CYAN}┌─ PRÓXIMOS PASOS ────────────────────────────────────────────┐${NC}"
echo -e "  1️⃣  Abre tu navegador en: ${GREEN}http://${CONTAINER_IP}:81${NC}"
echo -e "  2️⃣  Inicia sesión con las credenciales anteriores"
echo -e "  3️⃣  Cambia la contraseña desde el panel de administración"
echo -e "  4️⃣  Configura tus proxies y certificados SSL"
echo -e "${CYAN}└──────────────────────────────────────────────────────────${NC}"
echo ""
echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Instalador creado por: 3KNOX${NC}"
echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo ""

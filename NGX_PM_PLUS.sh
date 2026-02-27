#!/bin/bash
set -e

# ---------------- COLORES ----------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${CYAN}==============================================="
echo "  NGINX PROXY MANAGER TODO-EN-UNO PARA PROXMOX"
echo -e "===============================================${NC}"

# ---------------- MENÚ DE OPTIMIZACIÓN ----------------
echo "Selecciona el nivel de optimización para el contenedor:"
echo "1) Normal - 512MB RAM, 1 CPU, disco 10GB"
echo "2) Media - 1024MB RAM, 2 CPU, disco 15GB"
echo "3) Excelente - 2048MB RAM, 2 CPU, disco 20GB + backups automáticos"
read -p "Opción (1-3): " OPT_LEVEL

case "$OPT_LEVEL" in
  1)
    RAM=512
    CPU=1
    DISK=10
    BACKUP="no"
    ;;
  2)
    RAM=1024
    CPU=2
    DISK=15
    BACKUP="no"
    ;;
  3)
    RAM=2048
    CPU=2
    DISK=20
    BACKUP="si"
    ;;
  *)
    echo -e "${RED}Opción no válida. Saliendo...${NC}"
    exit 1
    ;;
esac

echo -e "${CYAN}Configuración seleccionada:${NC} RAM=${RAM}MB, CPU=${CPU}, Disco=${DISK}GB, Backups=${BACKUP}"

# ---------------- DATOS DEL CONTENEDOR ----------------
read -p "VMID del contenedor a crear (ej: 9000): " CTID
read -p "Nombre del contenedor (hostname): " HOSTNAME
read -p "Nodo de Proxmox donde se creará: " NODE
read -p "Bridge de red (default vmbr0): " BRIDGE
BRIDGE=${BRIDGE:-vmbr0}

# ---------------- CONTRASEÑAS ----------------
echo -e "${CYAN}Introduce las contraseñas que se usarán:${NC}"
read -p "Contraseña ROOT para MariaDB: " DB_ROOT_PASS
read -p "Usuario NPM para base de datos (default npm): " DB_NPM_USER
DB_NPM_USER=${DB_NPM_USER:-npm}
read -p "Contraseña NPM para la base de datos: " DB_NPM_PASS

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

# ---------------- DETECTAR IP DEL CONTENEDOR ----------------
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

# ---------------- RESUMEN FINAL ----------------
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Instalación completada!${NC}"
echo -e "${CYAN}Accede a Nginx Proxy Manager en: http://${CONTAINER_IP}:81${NC}"
echo -e "${CYAN}Usuario inicial: admin@example.com${NC}"
echo -e "${CYAN}Contraseña inicial: changeme${NC}"
if [[ "$BACKUP" == "si" ]]; then
  echo -e "${YELLOW}Backups automáticos disponibles en: /root/nginx-proxy-manager/backups${NC}"
fi
echo -e "${GREEN}===============================================${NC}"
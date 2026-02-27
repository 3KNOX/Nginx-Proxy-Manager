# 📚 DOCUMENTACIÓN TÉCNICA - NGX_PM_PLUS V2.0

## 🎯 Descripción General

**NGX_PM_PLUS_V2.sh** es un instalador profesional para **Nginx Proxy Manager** en Proxmox VE que automatiza:
- Creación de contenedor LXC Debian 13
- Instalación de Docker + Docker Compose
- Configuración de MariaDB integrada
- Despliegue de Nginx Proxy Manager
- Gestión persistente de configuración
- Backups automáticos (niveles altos)
- Edición de URLs sin modificar código

---

## 🔄 Flujo de Ejecución Detallado

### FASE 1: Menú Principal (Opciones 0-7)
```
┌─ MENÚ PRINCIPAL ──────────────────────────────────────────┐
[1] 🟢 INSTALAR - Nivel NORMAL
[2] 🟡 INSTALAR - Nivel MEDIA
[3] 🔵 INSTALAR - Nivel EXCELENTE
[4] 🔄 REINSTALAR - Mantener datos (próx)
[5] ⬆️  ACTUALIZAR - Dependencias (próx)
[6] 🌐 EDITAR URLs - Cambiar links ✅
[7] 📋 VER CONFIG - Mostrar guardada ✅
[0] ❌ SALIR
└───────────────────────────────────────────────────────────┘
```

### FASE 2: Selección de Optimización (si instala)
```
┌─ CONFIGURACIÓN DE RECURSOS ─────────────────────────────┐
[1] 🟢 NORMAL - Aplicaciones ligeras
    └─ RAM: 512 MB  | CPU: 1 core  | Disco: 10GB
[2] 🟡 MEDIA - Producción estándar
    └─ RAM: 1024 MB | CPU: 2 cores | Disco: 15GB
[3] 🔵 EXCELENTE - Producción crítica
    └─ RAM: 2048 MB | CPU: 2 cores | Disco: 20GB + Backups ✓
└──────────────────────────────────────────────────────────┘
```

**Variables asignadas:**
```bash
RAM=512|1024|2048    DISK=10|15|20
CPU=1|2              BACKUP=no|si
PROFILE=emoji+texto
```

### FASE 3: Recopilación de Datos
```
Solicita interactivamente con validaciones:
├─ VMID         (3-5 dígitos, sin duplicidad)
├─ HOSTNAME     (no vacío)
├─ NODE         (no vacío)
├─ BRIDGE       (default: vmbr0)
├─ DB_ROOT_PASS (contraseña oculta)
├─ DB_NPM_USER  (default: npm)
└─ DB_NPM_PASS  (contraseña oculta)
```

### FASE 4: Resumen & Confirmación
```
╔════ RESUMEN DE INSTALACIÓN ════╗
  VMID: 9000
  Hostname: npm-prod
  Nodo: pve
  Bridge: vmbr0
  Perfil: 🔵 EXCELENTE
  RAM: 2048MB | CPU: 2 | Disco: 20GB
════════════════════════════════
¿Confirmas? (s/n):
```

### FASE 5: Creación del Contenedor LXC
```bash
pct create $CTID $TEMPLATE \
    --cores $CPU \
    --memory $RAM \
    --swap 512 \
    --rootfs local:$DISK \
    --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
    --hostname $HOSTNAME

pct start $CTID
```

**Template usado:** `debian-13-standard_13.0-1_amd64.tar.gz`

### FASE 6: Script de Instalación Interna
Se ejecuta dentro del contenedor via heredoc + `pct exec`:

#### 6.1 - Actualizar Sistema
```bash
apt update && apt upgrade -y
apt install -y curl ca-certificates gnupg lsb-release sudo \
              vim net-tools jq apt-transport-https \
              software-properties-common procps iputils-ping
```

**Paquetes incluidos:**
| Paquete | Función |
|---------|---------|
| `curl` | Descargar scripts e imágenes |
| `ca-certificates` | Validar certificados SSL |
| `gnupg` | Firmas de paquetes |
| `lsb-release` | Info del SO |
| `jq` | Parseo JSON |
| `apt-transport-https` | HTTPS en APT |
| `software-properties-common` | Gestión de repos |
| `procps` | Utilidades ps, top |
| `iputils-ping` | Validar conectividad |

#### 6.2 - Instalar Docker
```bash
curl -fsSL $DOCKER_URL -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
systemctl enable docker
systemctl start docker
```

**Default:** `https://get.docker.com`

#### 6.3 - Instalar Docker Compose
```bash
COMPOSE_VERSION=2.20.0 (configurable)
curl -L https://github.com/docker/compose/releases/download/v${VERSION}/docker-compose-...
chmod +x /usr/local/bin/docker-compose
```

**Con fallback a v2.20.0 si error**

#### 6.4 - Crear Estructura de Directorios
```bash
NPM_ROOT=/root/nginx-proxy-manager
mkdir -p $NPM_ROOT/{data/mysql,letsencrypt,backups}
docker network create npm_network
```

#### 6.5 - Docker Compose Configuration
Archivo: `/root/nginx-proxy-manager/docker-compose.yml`

**Servicio: npm_app (Nginx Proxy Manager)**
```yaml
image: jc21/nginx-proxy-manager:latest  # configurable
container_name: npm_app
restart: unless-stopped
ports:
  - "80:80"      # HTTP
  - "443:443"    # HTTPS
  - "81:81"      # Panel de control
environment:
  TZ: 'America/Mexico_City'
  DB_MYSQL_HOST: 'npm_db'
  DB_MYSQL_PORT: 3306
  DB_MYSQL_USER: npm
  DB_MYSQL_PASSWORD: '${NPM_PASS_ESCAPED}'
  DB_MYSQL_NAME: 'npm'
volumes:
  - ./data:/data              # Configuración
  - ./letsencrypt:/etc/letsencrypt  # Certificados
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:81"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Servicio: npm_db (MariaDB)**
```yaml
image: jc21/mariadb-aria:latest  # configurable
container_name: npm_db
restart: unless-stopped
environment:
  MYSQL_ROOT_PASSWORD: '${ROOT_PASS_ESCAPED}'
  MYSQL_DATABASE: 'npm'
  MYSQL_USER: npm
  MYSQL_PASSWORD: '${NPM_PASS_ESCAPED}'
  MARIADB_AUTO_UPGRADE: '1'
volumes:
  - ./data/mysql:/var/lib/mysql  # Persistencia
healthcheck:
  test: ["CMD", "mariadb-admin", "ping", "-h", "127.0.0.1"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

#### 6.6 - Levantar Contenedores
```bash
for i in {1..3}; do
  if docker-compose up -d; then
    echo 'OK'
    break
  else
    echo "Reintento $i/3..."
    sleep 5
  fi
done
```

**Con reintentos automáticos (3 intentos, 5s entre intentos)**

#### 6.7 - Script de Backups (si BACKUP=si)
```bash
#!/bin/bash
BACKUP_DIR=/root/nginx-proxy-manager/backups
mkdir -p $BACKUP_DIR
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Dump de BD
docker exec npm_db /usr/bin/mysqldump -u root -p'$PASS' npm \
    > "$BACKUP_DIR/npm_db_$TIMESTAMP.sql"

# Empaquetado de datos
tar -czf "$BACKUP_DIR/npm_data_$TIMESTAMP.tar.gz" \
    -C /root/nginx-proxy-manager data
```

**Uso:**
```bash
cd /root/nginx-proxy-manager
./backup_npm.sh
```

### FASE 7: Detección de IP (Con 30 Reintentos)
```bash
CONTAINER_IP=""
for i in {1..30}; do
    CONTAINER_IP=$(pct exec $CTID -- hostname -I 2>/dev/null | awk '{print $1}')
    if [[ ! -z "$CONTAINER_IP" && "$CONTAINER_IP" != "" ]]; then
        echo "✓ IP detectada: $CONTAINER_IP"
        break
    else
        echo -n "."
        sleep 1
    fi
done
```

**Timeout:** 30 segundos (1s por intento)

### FASE 8: Guardar Configuración
```bash
cat > /root/.npm_config << EOF
LAST_VMID=$CTID
LAST_HOSTNAME=$HOSTNAME
LAST_NODE=$NODE
LAST_BRIDGE=$BRIDGE
LAST_PROFILE=$PROFILE
LAST_CPU=$CPU
LAST_RAM=$RAM
LAST_DISK=$DISK
LAST_BACKUP=$BACKUP

DOCKER_URL=${DOCKER_URL:-$DEFAULT_DOCKER_URL}
COMPOSE_VERSION=${COMPOSE_VERSION:-$DEFAULT_COMPOSE_VERSION}
NPM_IMAGE=${NPM_IMAGE:-$DEFAULT_NPM_IMAGE}
DB_IMAGE=${DB_IMAGE:-$DEFAULT_DB_IMAGE}
EOF
```

### FASE 9: Mostrar Resumen Final
```
╔════════════════════════════════════════════════════════════╗
║            ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE ✅     ║
╚════════════════════════════════════════════════════════════╝

┌─ INFORMACIÓN DE ACCESO ───────────────────────────────────┐
  🌐 URL: http://192.168.1.50:81
  👤 Usuario: admin@example.com
  🔑 Contraseña: changeme
└────────────────────────────────────────────────────────────┘

┌─ DETALLES DEL CONTENEDOR ─────────────────────────────────┐
  📌 VMID: 9000
  📍 Hostname: npm-prod
  🖧 IP: 192.168.1.50
  ⚙️  Perfil: 🔵 EXCELENTE
└────────────────────────────────────────────────────────────┘
```

---

## 🔒 Validaciones Incluidas

| Validación | Descripción |
|-----------|-------------|
| **VMID Existencia** | Verifica con `pct status $CTID` si ya corre |
| **VMID Formato** | Valida 3-5 dígitos numéricos |
| **Hostname No Vacío** | Loop hasta entrada válida |
| **Node No Vacío** | Loop hasta entrada válida |
| **Template Disponible** | Busca en `/var/lib/vz/template/cache/` |
| **Internet** | Ping a 8.8.8.8 antes de instalar |
| **Contraseñas Ocultas** | Uso de `read -sp` |
| **Password Escaping** | Sed para quotes y backslashes en YAML |
| **Menú Válido** | Regex `^[0-7]$` con loop si inválido |
| **IP Detection** | 30 reintentos x 1s cada uno |

---

## 🛡️ Seguridad

### Escapado de Contraseñas (CRITICAL)
```bash
# Problema: Si contraseña contiene ' o \, YAML se rompe
# Solución: Escapar antes de usarla en docker-compose.yml

ROOT_PASS_ESCAPED=$(printf '%s' "$DB_ROOT_PASS" \
    | sed "s/'/\\\\\\\\'/g" \
    | sed 's/\\/\\\\\\\\\\\\/g')

NPM_PASS_ESCAPED=$(printf '%s' "$DB_NPM_PASS" \
    | sed "s/'/\\\\\\\\'/g" \
    | sed 's/\\/\\\\\\\\\\\\/g')
```

**Qué hace:**
1. `sed "s/'/\\\\\\\\'/g"` - Convierte `'` a `\'`
2. `sed 's/\\/\\\\\\\\\\\\/g'` - Convierte `\` a `\\`

### Otros Aspectos
- ✅ Contraseñas NO se guardan en `.npm_config`
- ✅ Contraseñas NO aparecen en logs
- ✅ Terminal limpia después de input sensible
- ✅ Permisos restrictivos recomendados en `/root/.npm_config`

---

## 📦 Gestión de URLs (Opción [6])

**Función:** Cambiar URLs de Docker, Compose, imágenes SIN editar código

```
┌─ EDITAR URLs ────────────────────────────────────────────┐

  Actual Docker: https://get.docker.com
  Nueva URL Docker (Enter para mantener): 

  Actual Compose: 2.20.0
  Nueva versión (Enter para mantener): 

  Imagen NPM: jc21/nginx-proxy-manager:latest
  Nueva imagen (Enter para mantener):

  Imagen BD: jc21/mariadb-aria:latest
  Nueva imagen (Enter para mantener):

└──────────────────────────────────────────────────────────┘
```

**Flujo:**
1. Carga valores de `/root/.npm_config` si existen
2. Solicita nuevos valores (Enter = mantener)
3. Guarda en `.npm_config`
4. Próxima instalación usará estos valores

---

## 📋 Ver Configuración (Opción [7])

**Función:** Mostrar valores guardados de instalaciones previas

```
┌─ CONFIGURACIÓN GUARDADA ─────────────────────────────────┐

  DATOS DEL CONTENEDOR:
    📌 VMID: 9000
    📍 Hostname: npm-prod
    🖧 Nodo: pve
    🌉 Bridge: vmbr0
    ⚙️  Perfil: 🔵 EXCELENTE

  URLs CONFIGURADAS:
    🔗 Docker: https://get.docker.com
    🔗 Compose: 2.20.0
    🐳 Imagen NPM: jc21/nginx-proxy-manager:latest
    📦 Imagen BD: jc21/mariadb-aria:latest

└──────────────────────────────────────────────────────────┘
```

---

## 📂 Archivos Generados

### En el HOST (/root/)
```
.npm_config                    # Configuración persistente
npm_installer.log              # Log de instalación
NGX_PM_PLUS_V2.sh             # Este script
```

### En el Contenedor (/root/nginx-proxy-manager/)
```
docker-compose.yml             # Definición de servicios
data/mysql/                    # Base de datos persistente
data/npm/                      # Configuración NPM
letsencrypt/                   # Certificados SSL
backups/                       # Backups automáticos (nivel 3)
backup_npm.sh                  # Script de backup
install_npm.sh                 # Script de instalación (heredoc)
```

---

## 🔄 Problemas Corregidos (v1.0 → v2.0)

### Corrección 1: Validación de Variables Vacías
```bash
# ❌ Antes: Aceptaba vacíos silenciosamente
read -p "Hostname: " HOSTNAME

# ✅ Después: Loop hasta valor válido
while true; do
    read -p "Hostname: " HOSTNAME
    if [[ -z "$HOSTNAME" ]]; then
        echo "❌ No puede estar vacío"
    else
        break
    fi
done
```

### Corrección 2: Validación de VMID Duplicidad
```bash
# ✅ Antes de crear, verifica:
if pct status $CTID &>/dev/null; then
    echo "❌ VMID $CTID ya existe"
else
    pct create $CTID ...
fi
```

### Corrección 3: Verificación de Template
```bash
# ✅ Busca template en caché:
if ! ls /var/lib/vz/template/cache/debian-13-standard* \
        &>/dev/null; then
    echo "❌ Template no found. Download:"
    echo "pveam download local debian-13-standard_13.0-1_amd64.tar.gz"
    return 1
fi
```

### Corrección 4: Escapado de Contraseñas
```bash
# ✅ Escapar antes de usar en YAML:
ROOT_PASS_ESCAPED=$(printf '%s' "$DB_ROOT_PASS" \
    | sed "s/'/\\\\\\'/g" | sed 's/\\/\\\\\\/g')
```

### Corrección 5: Detección de IP Mejorada
```bash
# ❌ Antes: sleep 3 static (insuficiente)
sleep 3
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

# ✅ Después: 30 reintentos con feedback visual
for i in {1..30}; do
    CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
    if [[ ! -z "$CONTAINER_IP" ]]; then
        break
    fi
    sleep 1
done
```

---

## 🎨 Mejoras V2.0

| Mejora | Beneficio |
|--------|-----------|
| **Menú principal 8 opciones** | Más funcionalidad sin agregar items |
| **Config persistente** | Reutilizar settings en futuras instancias |
| **URL Editor** | Cambiar links sin editar bash |
| **Healthchecks** | Verificar que servicios estén listos |
| **Reintentos** | Mayor confiabilidad en levantamiento |
| **Logging completo** | Debugging y auditoría |
| **Password escaping** | Soporte para contraseñas complejas |
| **IP Detection loop** | Tolera DHCP lento |

---

## ⚙️ Próximas Funcionalidades

- [ ] **[4] REINSTALAR** - Mantener datos de instalación anterior
- [ ] **[5] ACTUALIZAR** - Actualizar Docker, Compose, paquetes APT
- [ ] **Interfaz gráfica** - Dashboard de monitoreo
- [ ] **Multi-node** - Organizar múltiples NPM instancias
- [ ] **Alertas** - Email/webhook si servicios caen

---

## 👨‍💻 Créditos

**Creado por:** 3KNOX  
**Versión:** 2.0  
**Última actualización:** Febrero 2026

---

## 📄 Licencia

MIT License - Libre para usar, modificar y distribuir

# Análisis del Script NGX_PM_PLUS.sh

## 📋 QUÉ HACE EL SCRIPT

El script automatiza la instalación de **Nginx Proxy Manager** en un contenedor LXC de Proxmox con:
- Base de datos MariaDB integrada
- Docker y Docker Compose
- Cert management automático (Let's Encrypt)
- Opción de backups automáticos

---

## 🔄 FLUJO DE EJECUCIÓN

### 1️⃣ ETAPA: Selección de Optimización (Líneas 17-47)
```
Menu interactivo: ¿Qué nivel de recursos?
1) Normal:    512MB RAM, 1 CPU, 10GB disco
2) Media:    1024MB RAM, 2 CPU, 15GB disco  
3) Excelente: 2048MB RAM, 2 CPU, 20GB disco + Backups
```
**Resultado:** Variables RAM, CPU, DISK, BACKUP

---

### 2️⃣ ETAPA: Recopilación de Datos (Líneas 50-69)
```
Solicita:
- CTID: ID del contenedor (ej: 9000)
- HOSTNAME: Nombre del contenedor
- NODE: Nodo Proxmox donde crear
- BRIDGE: Red virtual (default vmbr0)
- DB_ROOT_PASS: Contraseña root MariaDB
- DB_NPM_USER: Usuario BD (default "npm")
- DB_NPM_PASS: Contraseña usuario NPM
```

---

### 3️⃣ ETAPA: Crear Contenedor LXC (Líneas 72-92)
```bash
pct create $CTID $TEMPLATE \
    --cores $CPU \
    --memory $RAM \
    --swap 512 \
    --rootfs local:$DISK \
    --net0 name=eth0,bridge=$BRIDGE,ip=dhcp
```

**Template usado:** `debian-13-standard_13.0-1_amd64.tar.gz`

**Lo que hace:**
1. Crea contenedor LXC con ID $CTID
2. Asigna recursos (CPU, RAM, disco)
3. Configura red DHCP en bridge
4. Lo inicia automáticamente

---

### 4️⃣ ETAPA: Instalación Backend Dentro del Contenedor (Líneas 95-180)

Ejecuta `/root/install_npm.sh` DENTRO del contenedor:

#### A) Actualización del sistema
```bash
apt update && apt upgrade -y
apt install -y curl docker ca-certificates gnupg lsb-release
```

#### B) Instalación de Docker + Docker Compose
```bash
# Descarga script oficial de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

#### C) Configuración de Directorios
```
/root/nginx-proxy-manager/
├── data/mysql/           # BD MariaDB
├── letsencrypt/          # Certificados SSL
└── backups/              # Backups (si nivel 3)
```

#### D) Creación de Red Docker
```bash
docker network create npm_network
```

#### E) Docker Compose (Líneas 130-165)
Levanta 2 servicios:

**Servicio 1: npm_app** (Nginx Proxy Manager)
```yaml
image: jc21/nginx-proxy-manager:latest
Puertos: 80, 443, 81
Variables: Base datos MariaDB, zona horaria
```

**Servicio 2: npm_db** (MariaDB)
```yaml
image: jc21/mariadb-aria:latest
BD: npm
Usuario/Pass: Variables de entrada
```

#### F) Backups Automáticos (solo si nivel 3 elegido)
```bash
# Crea script /root/nginx-proxy-manager/backup_npm.sh
# Hace backup de:
# - Base datos: mysqldump
# - Datos: tar.gz de /data
```

---

### 5️⃣ ETAPA: Resumen Final (Líneas 185-196)

Muestra:
- ✅ IP del contenedor detectada con: `pct exec $CTID -- hostname -I`
- 🌐 URL acceso: `http://{IP}:81`
- 👤 Usuario: `admin@example.com`
- 🔑 Contraseña: `changeme`
- 💾 Ubicación backups (si aplica)

---

## ✅ REQUISITOS PARA QUE FUNCIONE

### En el HOST Proxmox:
- [ ] Proxmox VE (cualquier versión reciente)
- [ ] Template `debian-13-standard_13.0-1_amd64.tar.gz` disponible
- [ ] Acceso a red pública (descargar Docker/Docker Compose)
- [ ] Espacio en storage local (mínimo 10-20GB)

### Permisos necesarios:
- [ ] Usuario con permisos de crear contenedores LXC
- [ ] El script debe ejecutarse como **root**

---

## ⚠️ PROBLEMAS ENCONTRADOS Y SOLUCIONES

### ❌ PROBLEMA 1: Template predefinido
**Línea 72:**
```bash
TEMPLATE="local:vztmpl/debian-13-standard_13.0-1_amd64.tar.gz"
```

**Riesgo:** Si el template NO existe en tu Proxmox, el script falla.

**Solución:**
```bash
# En Proxmox, verifica templates disponibles:
pveam available
# O busca localmente:
ls /var/lib/vz/template/cache/
```

---

### ❌ PROBLEMA 2: Variables de red no validadas
**Línea 58:**
```bash
read -p "Nodo de Proxmox donde se creará: " NODE
```

**Riesgo:** Si NODE no existe, `pct create` falla.

**Solución:** El script debería validar:
```bash
if ! pvesh get /nodes/$NODE > /dev/null 2>&1; then
    echo "Nodo $NODE no existe"
    exit 1
fi
```

---

### ❌ PROBLEMA 3: Bridge de red puede no existir
**Línea 59:**
```bash
read -p "Bridge de red (default vmbr0): " BRIDGE
```

**Riesgo:** Si BRIDGE incorrecto, contenedor no tendrá red.

**Solución:** Validar antes de crear:
```bash
if ! ip link show $BRIDGE &>/dev/null; then
    echo "Bridge $BRIDGE no existe"
    exit 1
fi
```

---

### ❌ PROBLEMA 4: Falta detectar IP correctamente
**Línea 188:**
```bash
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
```

**Riesgo:** Si DHCP es lento, IP puede no estar asignada.

**Solución:** Añadir espera:
```bash
sleep 5  # Esperar DHCP
CONTAINER_IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
```

---

### ❌ PROBLEMA 5: Contraseña exposición
**Línea 101, 123:**
```bash
read -p "Contraseña ROOT para MariaDB: " DB_ROOT_PASS
```

**Riesgo:** Contraseña visible en terminal y en historial bash.

**Solución:** Usar `read -s` (sin echo):
```bash
read -s -p "Contraseña ROOT para MariaDB: " DB_ROOT_PASS
echo
```

---

### ❌ PROBLEMA 6: Error si Docker Compose latest no descarga
**Líneas 110-114:**
```bash
COMPOSE_LATEST=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest)
```

**Riesgo:** Si GitHub está down, falla silenciosamente.

**Solución:** Validar curl:
```bash
if ! COMPOSE_LATEST=$(curl -fsSL ... 2>/dev/null); then
    echo "Error descargando Docker Compose"
    exit 1
fi
```

---

## 🧪 CÓMO TESTEAR EN PROXMOX

### PASO 1: Preparación
```bash
# En nodo Proxmox, como root:
cd /root
cp NGX_PM_PLUS.sh .
chmod +x NGX_PM_PLUS.sh

# Verifica que tienes template
pveam available | grep debian-13
```

### PASO 2: Test en seco (sin crear contenedor)
```bash
# Valida sintaxis
bash -n /root/NGX_PM_PLUS.sh

# O instala shellcheck
apt install shellcheck
shellcheck /root/NGX_PM_PLUS.sh
```

### PASO 3: Ejecución real
```bash
# Ejecuta el script
bash /root/NGX_PM_PLUS.sh

# Cuando pregunte, usa:
# Opción: 2 (Media)
# CTID: 9000
# Hostname: npm-server
# Nodo: nombre_tu_nodo (ej: pve)
# Bridge: vmbr0 (default)
# DB Root Pass: MiContraseñaSegura123!
# DB NPM User: npm (default)
# DB NPM Pass: NpmPass123!
```

### PASO 4: Verificaciones después
```bash
# Ver estado del contenedor
pct status 9000
# Debe devolver: running

# Ver IP asignada
pct exec 9000 -- hostname -I

# Verificar Docker adentro
pct exec 9000 -- docker ps
# Debe mostrar npm_app y npm_db

# Acceder a web
# Abre: http://{IP_DEL_CONTENEDOR}:81
# User: admin@example.com
# Pass: changeme
```

---

## 📊 RESUMEN RÁPIDO

| Aspecto | Estado |
|--------|--------|
| **Sintaxis Bash** | ✅ Correcta |
| **Lógica general** | ✅ Correcta |
| **Validaciones** | ⚠️ Insuficientes |
| **Manejo errores** | ⚠️ Básico |
| **Seguridad** | ⚠️ Contraseñas expuestas |
| **Documentación** | ✅ Buena |
| **Reproducibilidad** | ✅ Alta |

---

## 🚀 CONCLUSIÓN

**¿Funcionará en Proxmox?** 
→ **SÍ**, si:
- ✅ Tienes el template Debian 13
- ✅ Tienes acceso a internet (Docker/Docker Compose)
- ✅ Datos NODE y BRIDGE son correctos
- ✅ Suficiente espacio disco

**Recomendaciones antes de usar:**
1. Validar disponibilidad del template
2. Mejorar validaciones de entrada (NODE, BRIDGE)
3. Añadir `read -s` para contraseñas
4. Aumentar timeout para asignación DHCP
5. Añadir verificaciones de errores en Docker install

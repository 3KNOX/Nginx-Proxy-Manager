# 🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER

![Version](https://img.shields.io/badge/version-2.0-green.svg)
![Proxmox](https://img.shields.io/badge/proxmox-7.x%2F8.x%2F9.x-orange.svg)
![Creator](https://img.shields.io/badge/creator-3KNOX-blue.svg)

**NGX_PM_PLUS.sh** - Instalador profesional con gestión de configuración, actualización de dependencias y menú avanzado para desplegar **Nginx Proxy Manager** en Proxmox VE.

---

## ✨ Características Principales

✅ **Menú principal con 8 opciones** - Instalación, reinstalación, actualización, edición de URLs  
✅ **Gestión de configuración persistente** - Archivo `.npm_config` para guardar settings  
✅ **3 perfiles de optimización** - Normal, Media, Excelente con recursos auto-asignados  
✅ **Creación automática** de contenedor LXC Debian 13  
✅ **Docker + Docker Compose** con instalación confiable y fallback  
✅ **Validaciones completas** - VMID, Hostname, Node, Template, Internet  
✅ **Nginx Proxy Manager** última versión con interfaz web  
✅ **MariaDB integrado** para persistencia de datos  
✅ **SSL/TLS automático** con Let's Encrypt  
✅ **Backups automáticos** (con nivel Excelente) con script incluido  
✅ **Healthchecks integrados** en Docker Compose  
✅ **IP detection mejorada** - 30 reintentos de DHCP  
✅ **Escapado de contraseñas** - Seguridad YAML para especiales caracteres  
✅ **Logging completo** en `/root/npm_installer.log`  
✅ **Editor de URLs** - Cambia docker, compose, imágenes sin editar código  
✅ **Interfaz colorida** con emojis y validaciones inteligentes  
✅ **Creador**: **3KNOX** 👨‍💻

---

## 📋 Requisitos

| Requisito | Detalle |
|-----------|---------|
| **Proxmox VE** | Versión 7.x, 8.x, 9.x o superior |
| **Permisos** | Acceso root al host Proxmox |
| **Template** | `debian-13-standard_13.0-1_amd64.tar.gz` disponible |
| **Almacenamiento** | Mínimo 20GB (recomendado 50GB) |
| **Conexión** | Internet d- Una Línea (Recomendado)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh)"
```

### Opción 2: Descargar y ejecutar localmente

```bash
# En tu Proxmox
wget -O /root/NGX_PM_PLUS.sh https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh
chmod +x /root/NGX_PM_PLUS.sh
bash /root/NGX_PM_PLUS.sh
```

### Opción 3: Direct Ejecutable

```bash
curl -fsSL https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh | bash
### Opción 2: Descargar y ejecutar localmente

```bash
# En tu Proxmox
wget -O /root/NGX_PM_PLUS.sh https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh
chm📊 Menú Principal (V2.0)

```
╔════════════════════════════════════════════════════════════╗
║     🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER 🚀         ║
║                        v2.0                               ║
║              Created by: 3KNOX                            ║
╚════════════════════════════════════════════════════════════╝

[1] 🟢 INSTALAR - Nivel NORMAL
[2] 🟡 INSTALAR - Nivel MEDIA
[3] 🔵 INSTALAR - Nivel EXCELENTE

[4] 🔄 REINSTALAR - Mantener datos (próximamente)
[5] ⬆️  ACTUALIZAR - Dependencias (próximamente)
[6] 🌐 EDITAR URLs - Cambiar links ✅
[7] 📋 VER CONFIG - Mostrar guardada ✅

[0] ❌ SALIR
```

## ⚙️ Configuración Interactiva

El script te solicitará según lo que selecciones:

### 1️⃣ Nivel de Optimización

- **🟢 Normal**: 512MB RAM, 1 CPU, 10GB disco → Desarrollo/Pruebas
- **🟡 Media**: 1024MB RAM, 2 CPU, 15GB disco → Producción estándar
- **🔵 Excelente**: 2048MB RAM, 2 CPU, 20GB disco + Backups automáticos

### 2️⃣ Datos del Con NPM

Una vez completada la instalación, el script te mostraña:

```
╔════ RESUMEN DE INSTALACIÓN ════╗
  VMID: 9000
  Hostname: npm-prod
  Nodo: pve
  Bridge: vmbr0
  Perfil: 🔵 EXCELENTE
  RAM: 2048MB | CPU: 2 | Disco: 20GB
  
  🌐 URL: http://192.168.1.50:81
  👤 Usuario: admin@example.com
  🔑 Contraseña: changeme
════════════════════════════════
```

⚠️ **IMPORTANTE**: 
1. Cambia la contraseña inmediatamente (`admin@example.com` → contraseña nueva)
2. Accede a `https://<IP>:443` si tienes certificado
3. Configura proxies y certificados según necesites
- Contraseña root de MariaDB (oculta)
- Usuario NPM (default: npm)
- Contraseña de usuario NPM (oculta)default: vmbr0)

### 3️⃣ Credenciales de Seguridad

- Contraseña root de MariaDB
- Usuario NPM (default: npm)
- Contraseña de usuario NPM

---

## 🌐 Acceso al Panel

Una vez completada la instalación:

- **URL**: `http://<IP_CONTENEDOR>:81`
- **Usuario**: `admin@example.com`
- **Contraseña**: `changeme`

⚠️ **IMPORTANTE**: Cambia la contraseña inmediatamente después del primer acceso.

---

## 📁 Estructura de Directorios

### En el HOST Proxmox:
```
/root/
├── .npm_config             → Config guardada (V2.0)
├── npm_installer.log       → Log de instalación
└── NGX_PM_PLUS_V2.sh      → Este script
```

### Dentro del contenedor:
```
/root/nginx-proxy-manager/
├── data/
│   ├── mysql/              → Base de datos MariaDB
│   ├── npm/                → Datos de configuración NPM
│   └── (datos persistentes)
├── letsencrypt/            → Certificados SSL/TLS
├── docker-compose.yml      → Configuración Docker Compose
├── backup_npm.sh           → Script de backups (nivel 3)
├── backups/                → Ubicación de backups
│   ├── npm_db_*.sql
│   └── npm_data_*.tar.gz
└── install_npm.sh          → Script interno de instalación
```

---

## 🔧 Configuración de Backups

Si seleccionas el nivel **Excelente**, se creará un script de backup automático:

```bash
# Ejecutar backup manual en el contenedor
cd /root/nginx-proxy-manager
./backup_npm.sh
```

**Archivos generados:**
- `npm_db_YYYYMMDD_HHMMSS.sql` → Dump de base de datos
- `npm_data_YYYYMMDD_HHMMSS.tar.gz` → Datos de configuración

---

## 📊 Niveles de Recursos Disponibles

| Nivel | RAM | CPU | Disco | Backups | Uso |
|-------|-----|-----|-------|---------|-----|
| Normal | 512 MB | 1 | 10 GB | ❌ | Desarrollo, pruebas |
| Media | 1024 MB | 2 | 15 GB | ❌ | Producción estándar |
| Ex� Gestión de Configuración (V2.0)

El script guarda automáticamente tu configuración en:
```bash
/root/.npm_config
```

**Contiene:**
```bash
LAST_VMID=9000
LAST_HOSTNAME=npm-prod
LAST_NODE=pve
LAST_BRIDGE=vmbr0
LAST_PROFILE=🔵 EXCELENTE
LAST_BACKUP=si

DOCKER_URL=https://get.docker.com
COMPOSE_VERSION=2.20.0
NPM_IMAGE=jc21/nginx-proxy-manager:latest
DB_IMAGE=jc21/mariadb-aria:latest
```

**Úsalo para:**
- Ver instalaciones previas: Opción `[7]`
- Editar URLs: Opción `[6]` (sin editar archivos)
- Reutilizar en reinstalaciones: Opción `[4]` (próx)

## 🔒 Seguridad

⚠️ **Recomendaciones:**

1. **Cambia credenciales por defecto** después de la instalación
2. **Configura firewall** en tu Proxmox para restringir acceso del Puerto 81
3. **Usa HTTPS** (Opción [6] para cambiar URLs a https)
4. **Realiza backups regulares** con script `backup_npm.sh` (nivel 3)
5. **Actualiza contenedor** regularmente: `pct exec 9000 -- docker-compose pull`
6. **Protege `/root/.npm_config`** con permisos restrictivos
✓ Detección de IP con espera de DHCP  
✓ Verificación de Docker en ejecución  

---

## 🔒 Seguridad

⚠️ **Recomendaciones:**

1. **Cambia credenciales por defecto** después de la instalación
2. **Configura firewall** en tu Proxmox para restringir acceso
3. **Usa HTTPS** en lugar de HTTP (configurable en NPM)
4. **Realiza backups regulares** si tienes datos críticos
5. **Actualiza contenedor** regularmente con `docker-compose pull`

---

## 🐛 Solución de Problemas

### El script no encuentra la plantilla Debian 13

```bash
# Verifica templates disponibles
pveam available | grep debian-13

# O descárgala
pveam update
pveam download local debian-13-standard_13.0-1_amd64.tar.gz
```

### El contenedor no conecta a internet

```bash
# Verifica el bridge de red
ip link show

# Reinicia el contenedor
pct restart 9000
```

### No puedo acceder al panel web

```bash
# Verifica que los contenedores estén corriendo
pct exec 9000 -- docker ps

# Revisa logs de Docker
pct exec 9000 -- docker-compose logs npm_app
```

---

## 📝 Logs y Debugging

```bash
# Conectar al contenedor
pct enter 9000

# Ver logs de Docker Compose
cd /root/nginx-proxy-manager
docker-compose logs -f

# Ver logs de MariaDB
docker-compose logs npm_db

# Ver logs NPM
docker-compose logs npm_app
```

---

## 🤝 Créditos

**Creado por 3KNOX**

Para reportar bugs o sugerir mejoras, abre un issue en GitHub.

---

## 📄 Licencia

Este proyecto está bajo licencia MIT.

---

## 🔗 Enlaces Útiles

- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Proxmox VE](https://www.proxmox.com/)
- [Docker](https://www.docker.com/)
- [MariaDB](https://mariadb.com/)

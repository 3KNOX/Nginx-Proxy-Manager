# 🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER

![Version](https://img.shields.io/badge/version-2.8.2-green.svg)
![Proxmox](https://img.shields.io/badge/proxmox-7.x%2F8.x%2F9.x-orange.svg)
![Creator](https://img.shields.io/badge/creator-3KNOX-blue.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

**NGX_PM_PLUS.sh** - Instalador automatizado todo-en-uno para desplegar **Nginx Proxy Manager** en Proxmox VE con un solo comando.

---

## ✨ Características Principales

- ✅ **Menú interactivo** con 6 opciones: 3 niveles de instalación + reinstalar + actualizar
- ✅ **IP estática configurable** - Solicita IP, máscara CIDR y gateway durante instalación (sin DHCP)
- ✅ **Creación automática** de contenedor LXC Debian 13 optimizado
- ✅ **Autodetección de almacenamiento** válido para LXC (búsqueda en pvesm:vztmpl)
- ✅ **Docker + Docker Compose plugin** (no legacy) instalados y configurados
- ✅ **Nginx Proxy Manager** última versión con interfaz web intuitiva
- ✅ **MariaDB Aria** para máximo rendimiento y persistencia
- ✅ **SSL/TLS automático** con Let's Encrypt integrado
- ✅ **Health checks avanzados** - espera inteligente para servicios
- ✅ **Credenciales seguras** - Paso de argumentos vs heredoc para evitar expansión incompleta
- ✅ **LXC Nesting habilitado** (--features nesting=1) para Docker en LXC
- ✅ **Gestión de configuración persistente** (.npm_config) con detección de corrupción
- ✅ **MOTD dinámico** - Información de contenedor en cada login
- ✅ **Reinstalar contenedor** - Opción [4] para destruir y recrear manteniendo configuración
- ✅ **Actualizar sistema** - Opción [5] para actualizar Debian, Docker e imágenes
- ✅ **Backups automáticos** (con nivel Excelente)
- ✅ **Interfaz colorida y accesible** - Emojis, spinners, validaciones en tiempo real

---

## 📋 Requisitos

| Requisito | Detalle |
|-----------|---------|
| **Proxmox VE** | Versión 7.x, 8.x, 9.x o superior |
| **Permisos** | Acceso root al host Proxmox |
| **Plantilla** | `debian-13-standard_13.0-1_amd64.tar.gz` disponible |
| **Almacenamiento** | Mínimo 20GB (recomendado 50GB) |
| **Conexión** | Internet de una línea (recomendado) |

---

## 🚀 Instalación Rápida

### Opción 1: Ejecutar directamente
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

### Opción 3: Ejecutable directo
```bash
curl -fsSL https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh | bash
```

---

## 📊 Menú Principal (V2.8.2)

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER 🚀         ║
║                        v2.8.2                              ║
║              Created by: 3KNOX                             ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────┐

  [1] 🟢 INSTALAR - Nivel NORMAL (512MB RAM | 1 CPU | 10GB)
  [2] 🟡 INSTALAR - Nivel MEDIA (1GB RAM | 2 CPU | 15GB)
  [3] 🔵 INSTALAR - Nivel EXCELENTE (2GB RAM | 2 CPU | 20GB + Backups)

  [4] 🔄 REINSTALAR - Limpiar y recrear contenedor
  [5] ⬆️  ACTUALIZAR - Sistema + Docker + Imágenes

  [0] ❌ SALIR

└───────────────────────────────────────────────────────────┘
```

---

## 📊 Niveles de Recursos

| Nivel | RAM | CPU | Disco | Backups | Uso |
|-------|-----|-----|-------|---------|-----|
| 🟢 **NORMAL** | 512 MB | 1 | 10 GB | ❌ | Desarrollo, pruebas |
| 🟡 **MEDIA** | 1024 MB | 2 | 15 GB | ❌ | Producción estándar |
| 🔵 **EXCELENTE** | 2048 MB | 2 | 20 GB | ✅ | Producción crítica |

---

## ⚙️ Flujo de Instalación

### 1️⃣ Seleccionar Nivel
- Elige entre NORMAL, MEDIA o EXCELENTE
- Los recursos se asignan automáticamente

### 2️⃣ Datos del Contenedor
Se solicitarán:
- **VMID**: Identificador único del contenedor (ej: 9000)
- **Hostname**: Nombre del contenedor (ej: npm-prod) - Asignado automáticamente
- **Nodo**: Host Proxmox (ej: pve) - Detectado automáticamente
- **Bridge**: Red virtual (default: vmbr0) - Detectado automáticamente

### 2️⃣.5️⃣ Configuración de IP Estática ⭐ NUEVO (v2.8.2)
- **IP del contenedor**: Solo ingresa la dirección IPv4 (ej: 192.168.1.100)
- **Máscara de red (CIDR)**: ✅ **Detectada automáticamente** del bridge
- **Gateway**: ✅ **Detectado automáticamente** del bridge

**El script lee `/etc/network/interfaces` para detectar la configuración del bridge automáticamente**

**NOTA**: El contenedor NO utilizará DHCP. La IP que configures será fija y persistente.

### 3️⃣ Credenciales de Seguridad
- Contraseña root para MariaDB
- Usuario NPM (default: npm)
- Contraseña NPM

### 4️⃣ Confirmación
Se muestra un resumen de todos los datos antes de instalar.

### 5️⃣ Instalación Automática
El script:
1. Crea el contenedor LXC
2. Instala Docker y Docker Compose
3. Despliega Nginx Proxy Manager
4. Configura MariaDB
5. Detecta la IP automáticamente
6. Guarda la configuración

---

## 🌐 Acceso Inicial

Una vez completada la instalación:

```
🌐 URL: http://<IP_CONTENEDOR>:81
👤 Usuario: admin@example.com
🔑 Contraseña: changeme
```

⚠️ **IMPORTANTE**: Cambia la contraseña inmediatamente después del primer acceso.

---

## 📁 Estructura de Directorios

### En el HOST Proxmox:
```
/root/
├── .npm_config              # Configuración guardada (V2.0)
├── npm_installer.log        # Registro de instalación
└── NGX_PM_PLUS.sh          # Este script
```

### Dentro del contenedor:
```
/root/nginx-proxy-manager/
├── data/
│   ├── mysql/              # Base de datos MariaDB
│   └── npm/                # Datos de configuración NPM
├── letsencrypt/            # Certificados SSL/TLS
├── docker-compose.yml      # Configuración Docker
├── backup_npm.sh           # Script de backups (nivel Excelente)
├── backups/                # Ubicación de backups
│   ├── npm_db_YYYYMMDD_HHMMSS.sql
│   └── npm_data_YYYYMMDD_HHMMSS.tar.gz
└── install_npm.sh          # Script interno de instalación
```

---

## 💾 Gestión de Configuración (V2.8.2)

El script guarda automáticamente tu configuración en:

**`/root/.npm_config`**

Contenido:
```bash
LAST_VMID=9000
LAST_HOSTNAME=npm-prod
LAST_NODE=pve
LAST_BRIDGE=vmbr0
LAST_PROFILE=🔵 EXCELENTE
LAST_BACKUP=si
LAST_CPU=2
LAST_RAM=2048
LAST_DISK=20
LAST_CONTAINER_IP=192.168.1.100
LAST_CONTAINER_CIDR=24
LAST_CONTAINER_GATEWAY=192.168.1.1

DOCKER_URL=https://get.docker.com
COMPOSE_VERSION=2.20.0
NPM_IMAGE=jc21/nginx-proxy-manager:latest
DB_IMAGE=jc21/mariadb-aria:latest
```

### Usar la configuración:

- **Ver instalaciones previas**: Opción `[7]` en el menú
- **Editar URLs**: Opción `[6]` (sin editar archivos)
- **Reutilizar en reinstalaciones**: Opción `[4]` (próxima versión)

---

## 🔧 Configuración de Backups

Si seleccionas el nivel **Excelente**, se creará un script de backup automático:

```bash
# Ejecutar backup manual en el contenedor
cd /root/nginx-proxy-manager
./backup_npm.sh
```

Archivos generados:
- `npm_db_YYYYMMDD_HHMMSS.sql` → Dump de base de datos
- `npm_data_YYYYMMDD_HHMMSS.tar.gz` → Datos de configuración

---

## 🔒 Seguridad

⚠️ **Recomendaciones Importantes:**

1. **Cambia credenciales por defecto** después de la instalación
2. **Configura firewall** en tu Proxmox para restringir el acceso al puerto 81
3. **Usa HTTPS** en lugar de HTTP (configurable en NPM)
4. **Realiza backups periódicos** si tienes datos críticos
5. **Actualiza el contenedor** periódicamente:
   ```bash
   pct exec 9000 -- docker-compose pull
   ```
6. **Protege el archivo de configuración** con permisos restrictivos:
   ```bash
   chmod 600 /root/.npm_config
   ```

---

## 🐛 Solución de Problemas

### Error 400: Storage no soporta contenedores

```
400 Parameter verification failed.
storage: storage 'local' does not support container directories
```

**Solución**: El script detecta automáticamente almacenamientos válidos (lvmthin, zfspool). Si ves este error:

1. El script te pedirá que selecciones almacenamiento
2. Si solo tienes `local` tipo `dir`, necesitas crear uno nuevo:

```bash
# Ver almacenamientos
pvesm status --content images

# Si solo ves 'local', consulta la guía: SOLUCION_ERROR_400.md
```

---

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

## 📝 Registros y Depuración

### Conectar al contenedor
```bash
pct enter 9000
```

### Ver logs de Docker Compose
```bash
cd /root/nginx-proxy-manager
docker-compose logs -f
```

### Ver logs específicos
```bash
# MariaDB
docker-compose logs npm_db

# NPM
docker-compose logs npm_app

# Instalación (en el host)
cat /root/npm_installer.log
```

---

## 🤝 Créditos

**Creado por**: [3KNOX](https://github.com/3KNOX)

Para informar errores o sugerir mejoras, abre un issue en GitHub.

---

## 📄 Licencia

Este proyecto está bajo licencia **MIT**. Ver archivo [LICENSE](LICENSE) para más detalles.

---

## 🔗 Enlaces Útiles

- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Proxmox VE](https://www.proxmox.com/)
- [Docker](https://docker.com/)
- [MariaDB](https://mariadb.org/)

---

## 📝 Notas de Versión

### v2.0 (Actual)
- ✅ Menú simplificado sin submenús redundantes
- ✅ 3 opciones de instalación directas desde menú principal
- ✅ Gestión de configuración persistente mejorada
- ✅ Editor de URLs embebido
- ✅ Visualización de configuración guardada
- ✅ Código reorganizado en 7 secciones claras

### v2.1 (Próximo)
- 🔲 Opción REINSTALAR con preservación de datos
- 🔲 Opción ACTUALIZAR de dependencias
- 🔲 Tests automatizados

---

**¿Necesitas ayuda?** Abre un issue en el repositorio de GitHub.

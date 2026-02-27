# CHANGELOG

Historial de cambios de NGX_PM_PLUS - NPM Installer para Proxmox

---

## [2.7.4] - 26 de Febrero de 2026

### 🔧 Mejoras Críticas

- **Paso de credenciales como argumentos** - Evita problemas de expansión de variables en heredocs
- **Seguridad mejorada** - Las contraseñas se pasan directamente al script, no se expanden en el host
- **Compatibilidad total** - Soluciona "Access denied for user" en conexión MariaDB

### 🐛 Bugs Corregidos

- ✅ Credenciales no se expandían correctamente en docker-compose.yml
- ✅ npm_app no podía autenticarse en MariaDB  
- ✅ Variables con caracteres especiales causaban errores silenciosos

---

## [2.7.3] - 26 de Febrero de 2026

### ✨ Nuevas Características

- **Health checks avanzados** - Docker Compose ahora espera a que MariaDB esté listo
- **Espera inteligente** - Verificación de servicios en bucle con reintentos
- **Netcat integrado** - Para detectar disponibilidad de puertos

### 🔧 Mejoras Técnicas

- `depends_on` con `condition: service_healthy` para npm_app
- Health check MariaDB: `mariadb-admin ping` cada 10 segundos (30 intentos)
- Health check Nginx: `curl http://localhost:81` cada 30 segundos (5 intentos)
- Espera post docker-compose-up para verificación manual
- Timeout de 60 segundos para cada servicio

---

## [2.7.2] - 26 de Febrero de 2026

### 🐛 Bugs Corregidos

- ✅ MOTD se mostraba 3-4 veces en login (duplicación en .bashrc)
- ✅ Debian 13 muestra /etc/motd automáticamente sin modificar .bashrc
- ✅ Eliminada línea redundante que agregaba MOTD múltiples veces

---

## [2.7.1] - 26 de Febrero de 2026

### 🔧 Mejoras Críticas

- **Corrección en búsqueda de templates** - Ahora busca en `pvesm list $storage:vztmpl`
- **Detección instantánea** - Reconoce templates existentes sin descargar innecesariamente
- **Optimización de tiempo** - Ahora NO descarga si el template ya existe

### 🐛 Bugs Corregidos

- ✅ Script buscaba en `--content images` en lugar de `:vztmpl`
- ✅ Siempre descargaba template aunque ya existiera
- ✅ Búsqueda en bucle de espera también corregida

---

## [2.7.0] - 26 de Febrero de 2026

### ✨ Arquitectura Completamente Refactorizada

- **Script host-based** - Crea scripts en /tmp, luego los copia al contenedor
- **Eliminación de heredoc anidado** - No más problemas de escaping en bash -c
- **Método pct push/exec** - Más robusto que inlining

### 🔧 Mejoras Técnicas

- Script creado en HOST: `/tmp/npm_install_${CTID}.sh`
- Copia al contenedor: `pct push`
- Ejecución limpia: `pct exec -- bash`
- Limpieza post-instalación: `rm -f /tmp/npm_install_${CTID}.sh`

### 🐛 Bugs Corregidos

- ✅ Eliminado código duplicado de instalación
- ✅ Heredoc anidado ya no causa truncación
- ✅ Variables se expanden correctamente ahora

---

## [2.6.0] - 25 de Febrero de 2026

### ✨ Nuevas Características

- **load_config() mejorado** - Detecta y limpia archivos de configuración corrupta
- **Detección de corrupción** - Si hay variables sin comillas con emojis, regenera archivo
- **Recuperación automática** - No bloquea instalación, regenera limpio

### 🔧 Mejoras Técnicas

- `load_config()` ahora captura stderr del `source`
- grep busca líneas que son comandos (indicio de corrupción)
- Sobrescribe archivo corrupto automáticamente
- Mantiene configuración válida intacta

---

## [2.5.0] - 25 de Febrero de 2026

### ✨ Nuevas Características

- **Nombre de contenedor customizable** - Cambiado a "Nginx-PMX" por defecto
- **Nombre de contenedor customizable** - Cambiado a "Nginx-PMX" por defecto
- **MOTD dinámico** - Información de contenedor en cada login
  - Hostname, IP, versión Debian
  - Información del creador/GitHub
  - Se muestra automáticamente al conectar

### 🔧 Mejoras Técnicas

- Script MOTD en `/etc/update-motd.d/00-header`
- Generación dinámica con `run-parts`
- Emojis integrados en mensaje de bienvenida
- Compatible con Debian 13 y posteriores

---

## [2.4.0] - 25 de Febrero de 2026

### ✨ Nuevas Características

- **LXC Nesting habilitado** - Docker ahora funciona dentro de contenedores LXC sin overlay errors
- **--features nesting=1** - Permite módulos kernel necesarios para containers dentro de containers

### 🔧 Mejoras Técnicas

- `pct create ... --features nesting=1`
- Eliminado `version: 3.8` de docker-compose.yml (obsoleto en Debian 13)
- Docker overlay filesystem ahora funciona correctamente

### 🐛 Bugs Corregidos

- ✅ Error: "failed to register layer: mkdir /var/lib/docker/overlay2/..."
- ✅ Contenedores Docker no iniciaban en LXC sin nesting

---

## [2.3.0] - 25 de Febrero de 2026

### ✨ Nuevas Características

- **Optimización Debian 13** - Actualizado para distro actual
- **Docker Compose plugin** - Cambio de docker-compose binary a plugin
- **Spinner animations** - Feedback visual mejorada

### 🔧 Mejoras Técnicas

- Eliminados: `software-properties-common`, `apt-transport-https` (no existen en Debian 13)
- Docker compose plugin en lugar de legacy binary
- LANG=C.UTF-8 + DEBIAN_FRONTEND=noninteractive para menos warnings
- Spinners con caracteres Unicode (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)

### 🐛 Bugs Corregidos

- ✅ Instalación 10x más rápida sin warnings de locale
- ✅ Compatibilidad total con Debian 13
- ✅ docker-compose-plugin funciona con docker compose (nuevo formato)

---

## [2.0.0 - 2.2.1] - Histórico

### ✨ Características Base

- Menú principal interactivo con 8 opciones
- Sistema de configuración persistente (.npm_config)
- Gestor de URLs integrado
- 3 perfiles de optimización (Normal, Media, Excelente)
- Autodetección de infraestructura (node, bridge, storage)
- Template Debian download y detección
- Contenedor LXC con Docker + Docker Compose
- MariaDB integrado
- Nginx Proxy Manager desplegado
- IP detection automático
- Logging e interfaz colorida

---

## [2.0] - 26 de Febrero de 2026

### ✨ Nuevas Características

- **Menú principal interactivo** con 8 opciones
  - [1-3] Instalación con 3 perfiles optimizados
  - [4] Reinstalación (próxima versión)
  - [5] Actualización automática (próxima versión)
  - [6] Editor de URLs embebido
  - [7] Visor de configuración guardada
  - [0] Salir

- **Sistema de configuración persistente**
  - Archivo `/root/.npm_config` guarda settings
  - Reutilización de datos en futuras instalaciones
  - No requiere re-ingreso de datos

- **Gestor de URLs integrado**
  - Cambiar URL de Docker sin editar código
  - Cambiar versión de Docker Compose
  - Cambiar imagen NPM
  - Cambiar imagen MariaDB
  - Configuración guardada automáticamente

- **Perfiles de optimización mejorados**
  - 🟢 NORMAL: 512MB, 1 CPU, 10GB (desarrollo)
  - 🟡 MEDIA: 1024MB, 2 CPU, 15GB (producción)
  - 🔵 EXCELENTE: 2048MB, 2 CPU, 20GB + backups

### 🔧 Mejoras Técnicas

- **Validaciones exhaustivas**
  - VMID: Formato 3-5 dígitos + verificación duplicidad
  - Hostname: No admite vacío
  - Node: No admite vacío
  - Template: Verifica existencia antes de crear
  - Internet: Valida conectividad antes de instalar

- **Detectación de IP robusta**
  - 30 reintentos de DHCP (1s cada uno)
  - Feedback visual con puntos de progreso
  - Timeout de 30 segundos total

- **Seguridad mejorada**
  - Escapado bidireccional de contraseñas
  - Protección contra caracteres especiales en YAML
  - Contraseñas ocultas en entrada (read -sp)
  - Logging completo en `/root/npm_installer.log`

- **Docker Compose robusto**
  - Healthchecks para NPM y MariaDB
  - Reintentos automáticos (3 intentos, 5s entre intentos)
  - Fallback a v2.20.0 si la versión falla
  - Red Docker aislada (npm_network)

- **Backups automáticos**
  - Script `backup_npm.sh` generado con nivel 3
  - Backups: base datos SQL + datos comprimidos
  - Timestamps automáticos (YYYYMMDD_HHMMSS)

### 📝 Logging Completo

- Todos los eventos registrados en `/root/npm_installer.log`
- Timestamps precisos en cada línea
- Información de depuración completa

### 🎨 Interfaz Mejorada

- Menú principal con colores y emojis
- Box formatting profesional (┌─ ─┐ │ └─ ─┘)
- Mensajes de estado con iconos (✓ ❌ ⚠️)
- Validaciones con reintentos automáticos
- Feedback visual en cada paso

---

## [1.0] - Inicial

### ✨ Características Iniciales

- Menú con 3 opciones de instalación
- Creación automática de contenedor LXC
- Instalación de Docker + Docker Compose
- Configuración de MariaDB integrada
- Despliegue de Nginx Proxy Manager
- Backups manuales
- Detección de IP básica
- Interfaz con colores ANSI

### 🔧 Funcionalidades Origales

- Validación básica de VMID y campos
- Contraseñas ocultas
- Resumen final de instalación
- Soporte para 3 niveles de recursos

---

## Próximas Características (v2.1)

### En Desarrollo

- [ ] Opción [4] - REINSTALAR con preservación de datos
- [ ] Opción [5] - ACTUALIZAR dependencias automáticamente

---

**Nota**: El script ya cumple su propósito principal:
- ✅ Automatización completa (sin pasos manuales)
- ✅ Instalación en un único comando
- ✅ Todas las dependencias incluidas
- ✅ Gestión de configuración persistente

Futuras versiones se enfocarán en las 2 opciones faltantes del menú.

---

## Cambios Técnicos Detallados

### v1.0 → v2.0

#### Problema 1: Variables no validadas
```bash
# ❌ v1.0
read -p "Hostname: " HOSTNAME
# Acepta vacío silenciosamente

# ✅ v2.0
while [[ -z "$HOSTNAME" ]]; do
    read -p "Hostname: " HOSTNAME
done
```

#### Problema 2: VMID duplicado sin validar
```bash
# ✅ v2.0
if pct status $CTID &>/dev/null; then
    echo "❌ VMID ya existe"
else
    pct create $CTID ...
fi
```

#### Problema 3: Template sin verificación
```bash
# ✅ v2.0
if ! ls /var/lib/vz/template/cache/debian-13-standard* &>/dev/null; then
    echo "❌ Template no encontrada"
    return 1
fi
```

#### Problema 4: Contraseñas con especiales rompen YAML
```bash
# ✅ v2.0
ROOT_PASS_ESCAPED=$(printf '%s' "$DB_ROOT_PASS" \
    | sed "s/'/\\\\'/g" | sed 's/\\/\\\\\\/g')
```

#### Problema 5: IP detection insuficiente (3s)
```bash
# ✅ v2.0
for i in {1..30}; do
    CONTAINER_IP=$(pct exec $CTID -- hostname -I)
    [[ ! -z "$CONTAINER_IP" ]] && break
    sleep 1
done
```

---

## Autores

- **3KNOX** - Creador principal

---

## Licencia

MIT License - Ver archivo LICENSE para detalles

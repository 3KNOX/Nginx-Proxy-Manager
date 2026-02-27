# CHANGELOG

Historial de cambios de NGX_PM_PLUS - NPM Installer para Proxmox

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

## Próximas Características (Roadmap)

### v2.1 - Próxima

- [ ] Opción [4] - REINSTALAR con preservación de datos
- [ ] Opción [5] - ACTUALIZAR dependencias automáticamente
- [ ] Migración de configuración entre versiones
- [ ] Rollback automático ante fallos

### v2.2

- [ ] Dashboard de monitoreo web
- [ ] Multi-node support
- [ ] Alertas por email/webhook
- [ ] API REST para automatización
- [ ] Integración con Grafana

### v3.0

- [ ] Interfaz gráfica (Web UI)
- [ ] Clúster de NPM
- [ ] Load balancing automático
- [ ] Métricas en tiempo real

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

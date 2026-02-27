# 🚀 NGINX PROXY MANAGER - PROXMOX INSTALLER

![Version](https://img.shields.io/badge/version-1.0-green.svg)
![Proxmox](https://img.shields.io/badge/proxmox-7.x%2F8.x-orange.svg)
![Creator](https://img.shields.io/badge/creator-3KNOX-blue.svg)

**NGX_PM_PLUS.sh** - Instalador automatizado todo-en-uno para desplegar **Nginx Proxy Manager** en Proxmox VE con un solo comando.

---

## ✨ Características Principales

✅ **Menú interactivo** con 3 niveles de optimización (Normal, Media, Excelente)  
✅ **Creación automática** de contenedor LXC Debian 13  
✅ **Docker + Docker Compose** instalados y configurados  
✅ **Nginx Proxy Manager** última versión con interfaz web  
✅ **MariaDB integrado** para persistencia de datos  
✅ **SSL/TLS automático** con Let's Encrypt  
✅ **Backups automáticos** (con nivel Excelente)  
✅ **Interfaz mejorada** con colores y validaciones  
✅ **Detección automática** de IP del contenedor  
✅ **Creador**: **3KNOX** 👨‍💻

## Requisitos

- Host Proxmox VE (7.x o 8.x) con permisos de root.  
- Plantilla Debian 13 (`debian-13-standard_13.0-1_amd64.tar.gz`) en el almacenamiento local de Proxmox.  
- Conexión a internet desde el host para descargar Docker, Docker Compose y NPM.  

## Instalación

1. Ejecutar directamente desde el host Proxmox con:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/refs/heads/main/NGX_PM_PLUS.sh)"

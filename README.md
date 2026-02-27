# Proxmox Nginx Proxy Manager Installer

Este repositorio contiene **NGX_PM_PLUS.sh**, un script todo-en-uno para Proxmox que crea un contenedor LXC Debian 13 y configura automáticamente **Nginx Proxy Manager** con Docker y Docker Compose.  

## Características

- Menú de optimización para RAM, CPU y disco.  
- Creación automática del contenedor Debian 13.  
- Instalación de Docker y Docker Compose.  
- Instalación y configuración de Nginx Proxy Manager (última versión).  
- Configuración de contraseñas de MariaDB y NPM.  
- Backups automáticos y script de actualización (opcional).  
- Detección automática de la IP del contenedor y URL del panel.  

## Requisitos

- Host Proxmox VE (7.x o 8.x) con permisos de root.  
- Plantilla Debian 13 (`debian-13-standard_13.0-1_amd64.tar.gz`) en el almacenamiento local de Proxmox.  
- Conexión a internet desde el host para descargar Docker, Docker Compose y NPM.  

## Instalación

1. Ejecutar directamente desde el host Proxmox con:

```bash

bash -c "$(curl -fsSL https://raw.githubusercontent.com/3KNOX/Nginx-Proxy-Manager/main/NGX_PM_PLUS.sh)"

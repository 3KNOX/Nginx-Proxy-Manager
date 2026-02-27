# Guía de Contribución

¡Gracias por tu interés en contribuir a NGX_PM_PLUS! 🎉

Este documento te ayudará a entender cómo contribuir al proyecto.

---

## Código de Conducta

- Sé respetuoso y constructivo
- Evita spam o contenido inapropiado
- Mantén la comunicación clara y profesional

---

## Cómo Reportar Bugs

### Antes de reportar:

1. Verifica que el bug NO esté reportado ya
2. Actualiza a la última versión
3. Revisa la documentación (README.md)

### Al reportar:

  **Título claro**: Describe el problema en pocas palabras

  **Descripción detallada**:
  - Qué esperabas que sucediera
  - Qué sucedió realmente
  - Pasos para reproducir

  **Contexto**:
  - Versión de Proxmox (7.x, 8.x, 9.x)
  - Versión del script (v1.0, v2.0, etc)
  - Sistema operativo del cliente

  **Logs**:
  ```bash
  cat /root/npm_installer.log
  ```

---

## Sugerencias de Mejoría

Si tienes una idea:

1. **Abre una Issue** con la etiqueta `enhancement`
2. **Describe la funcionalidad** que quieres
3. **Explica el beneficio** para los usuarios
4. **Da ejemplos** de cómo se usaría

---

## Pull Requests

### Antes de hacer un PR:

1. **Fork** el repositorio
2. **Crea una rama** descriptiva:
   ```bash
   git checkout -b feature/nueva-funcionalidad
   # o
   git checkout -b fix/nombre-del-bug
   ```

3. **Haz tus cambios** y commita frecuentemente:
   ```bash
   git commit -m "Añade descripción clara del cambio"
   ```

4. **Actualiza CHANGELOG.md** con tus cambios

### Estándares de Código

**Bash Script:**
```bash
#!/bin/bash

# Shebang al inicio
set -e              # Salir ante errores

# Funciones antes del main
my_function() {
    # Documentación inline
    local variable="valor"
    echo "Usa echo para output"
}

# Variables MAYUSCULA
CONFIG_FILE="/root/.npm_config"

# Indentación: 4 espacios
if [[ condition ]]; then
    echo "Sangría correcta"
fi
```

**Validaciones:**
```bash
# ✅ BIEN - Validar antes de usar
if [[ -z "$VARIABLE" ]]; then
    echo "Error: VARIABLE está vacía"
    return 1
fi

# ❌ MAL - Usar sin validar
echo "$VARIABLE"
```

**Mensajes de Usuario:**
```bash
# ✅ BIEN - Feedback claro
echo -e "${GREEN}✓ Operación exitosa${NC}"
echo -e "${RED}❌ Error encontrado${NC}"
echo -e "${YELLOW}⚠️  Advertencia${NC}"

# ❌ MAL - Sin formato
echo "Ok"
echo "Error"
```

---

## Estructura del Proyecto

```
NGX_PM_PLUS/
├── NGX_PM_PLUS.sh          ← Script principal (NO DUPLICAR)
├── README.md               ← Documentación
├── DOCUMENTACION.md        ← Technical deep-dive
├── CHANGELOG.md            ← Historial de cambios
├── LICENSE                 ← Licencia MIT
├── .gitignore              ← Archivos ignorados
└── CONTRIBUTING.md         ← Este archivo
```

---

## Proceso de Revisión

1. Crearás un PR con tus cambios
2. Será revisado por los mantenedores
3. Se pedirán cambios si es necesario
4. Una vez aprobado, será mergeado

**Tiempo esperado**: 3-7 días

---

## Áreas donde Necesitamos Ayuda

### 🔴 CRÍTICO

- [ ] Función [4] REINSTALAR
- [ ] Función [5] ACTUALIZAR
- [ ] Tests automatizados
- [ ] Documentación en Español mejorada

### 🟡 IMPORTANTE

- [ ] Soporte para otros templates (Ubuntu, Alpine)
- [ ] Configuración de SSL/TLS automático
- [ ] Integración con monitoring

### 🟢 NICE-TO-HAVE

- [ ] Interfaz gráfica
- [ ] Traducción a otros idiomas
- [ ] Dashboard web

---

## Comunicación

- **Issues**: Para bugs y features
- **Discussions**: Para preguntas y ideas
- **Email**: Contact al creador 3KNOX

---

## Licencia

Al contribuir, aceptas que tus cambios estarán bajo la licencia MIT.

---

## Créditos

Toda contribución será reconocida en el CHANGELOG.md

¡Gracias por contribuir! 🙌

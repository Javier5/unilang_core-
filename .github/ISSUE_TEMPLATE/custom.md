---
name: Reporte de Errores (Bug Report)
about: Reporta fallos de sintaxis, desbordamiento de memoria o incompatibilidades del sistema de higiene.
title: 'bug: [Escribe un resumen breve del problema aquí]'
labels: 'bug, unverified'
assignees: ''

---

**Descripción del Fallo**
Una descripción clara y concisa de lo que ocurre en el servidor o cliente. (Ej: *"Al usar el orinal, la animación se corta a los 2 segundos pero el cooldown se aplica igual"*).

**Pasos para Reproducir el Error**
Pasos exactos para recrear el problema:
1. Entrar al servidor con el personaje.
2. Dirigirse a la coordenada del baño en `Config.Locations`.
3. Presionar la tecla `[E]` e iniciar la secuencia de `[Acción]`.
4. Ver el error en la consola.

**Logs de Error e Implicaciones (Consola)**
Copia y pega aquí el error exacto que arroja la consola (F8 en el cliente o la consola de FXServer en el servidor):
```log
-- Pega aquí el código de error. Ej: [script:esx_bathroom] SCRIPT ERROR: @esx_bathroom/client.lua:142: attempt to index a nil value

---
name: Reporte de Error (Bug Report)
about: Crea un reporte detallado para ayudarnos a solucionar fallos en el sistema de higiene.
title: 'bug: [Escribe un resumen breve del fallo aquí]'
labels: 'bug, bajo-analisis'
assignees: ''

---

**Descripción del Error**
Una descripción clara y concisa de lo que está fallando. (Ej: *"El jugador se queda congelado después de terminar la animación de la ducha si se presiona otra tecla"*).

**Pasos para Reproducir el Fallo**
Pasos secuenciales para que el equipo de desarrollo pueda replicar el comportamiento errático en el servidor de pruebas:
1. Dirigirse a la coordenada de una ducha configurada en `Config.Locations`.
2. Presionar la tecla `[E]` para abrir el menú e iniciar la acción.
3. Esperar a que la barra de progreso llegue al 100%.
4. Intentar moverse inmediatamente y observar el error.

**Comportamiento Esperado**
Una descripción clara de lo que se suponía que debía ocurrir de acuerdo a la lógica del script. (Ej: *"Al terminar la barra de progreso, la posición de la entidad debería descongelarse por completo y las partículas de vapor deberían desaparecer"*).

**Capturas de Pantalla o Videos**
Si es aplicable, añade capturas de pantalla de la base de datos (guardado de metadata) o un fragmento de video que muestre el error de animación o interfaz.

**Entorno del Servidor (Por favor completa la siguiente información):**
 - Versión de Artifacts (FXServer): [e.g. Build 8500]
 - Versión de ESX Core: [e.g. Legacy v1.10.3]
 - Estado de base de datos: [e.g. MariaDB / MySQL-Async / Oxmysql]
 - Consola F8 / Server Log: [Copia y pega aquí cualquier línea de error en rojo que aparezca]

**Información del Cliente / Jugador (Opcional):**
 - Cliente de GTA: [e.g. Canary / Release]
 - Build de GTA V ejecutándose: [e.g. 3095 / 3258]
 - Rendimiento en Resmon: [e.g. 0.01ms / picos de lag]

**Contexto Adicional**
Cualquier otro detalle técnico pertinente, como si el fallo ocurre únicamente con personajes femeninos (debido a los diccionarios de animación de las duchas), o si hay interferencia con un script de HUD externo.

---
name: Feature request
about: Sistema de reacción de NPCs y penalizaciones comerciales por mala higiene corporal.
title: 'feat: Sistema de Reacción Social de NPCs y Efectos de Olor Desagradable'
labels: 'enhancement, in-game mechanics'
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
Actualmente, el script calcula de forma excelente la decaída de higiene en la base de datos y aplica alertas de texto en pantalla, pero la variable `socialPenalty` se queda corta en el entorno de juego real. Me resulta un poco plano que un jugador pueda estar con la higiene en 0% (literalmente oliendo a basura) y aun así pueda interactuar normalmente con los NPCs, comprar en las tiendas del mapa o caminar por la calle sin que el entorno reaccione a su estado.

**Describe the solution you'd like**
Me gustaría que se implementara una característica enlazada al bucle del `client.lua` y del `server.lua` que ejecute las siguientes mecánicas cuando el jugador cruce los umbrales críticos de suciedad (Higiene < 20%):

1. **Reacción Genérica de Peatones (Ambiental):** Si un jugador pasa corriendo o caminando cerca de un NPC civil en la calle, que el NPC reproduzca de forma aleatoria una animación de asco (como cubrirse la nariz o hacer gestos de desagrado usando la animación nativa de GTA `mp_player_int_upper_smell_lean`) y suelte líneas de voz nativas de queja (audios nativos de dolor/incomodidad).
2. **Restricción Comercial (Tiendas / Establecimientos):**
   Si el jugador intenta abrir un menú de interacción con un dependiente de tienda (por ejemplo, en un supermercado, ammunation o concesionario) teniendo la higiene en estado crítico, el dependiente debería negarse a atenderlo con un mensaje del tipo: *"No puedo atenderte en ese estado, por favor ve a una ducha y regresa limpio"*.
3. **Efecto de Partículas de Olor Pasivo:**
   Activar un bucle de partículas visuales verde o de moscas (`prop_flies_cargo` o `ent_amb_flies`) flotando de forma sutil alrededor del Ped del jugador cuando la higiene llegue a niveles inferiores al 10%.

**Describe alternatives you've considered**
* *Alternativa simple:* Aplicar un filtro de pantalla borroso o un efecto de tambaleo de cámara constante por "mareo/infección", pero considero que esto último castiga la jugabilidad del usuario en lugar de fomentar el rol social y el uso del baño/duchas que es el objetivo principal del script.

**Additional context**
Aprovechando que ya tenemos el sistema de partículas (`ptfx`) y las animaciones estructuradas en el cliente, la implementación de las moscas pasivas o las animaciones de los NPCs cercanos se puede resolver mediante un chequeo de proximidad de Peds (`GetNearbyPeds`) optimizado en el hilo de 500ms del cliente cuando la variable local `playerNeeds.hygiene` sea inferior a 20.

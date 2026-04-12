# Reglas de Widgets y UI

## Composicion
- MUST preferir widgets pequenos y reutilizables.
- MUST separar widgets de layout y widgets de comportamiento cuando crezcan.
- MUST NOT poner logica de negocio en `build()`.

## Estado de UI
- MUST usar `StatefulWidget` solo si hay estado local real.
- MUST elevar estado compartido al ancestro comun mas cercano.
- MUST diferenciar estado efimero de UI vs estado de dominio.

## Build y rebuild
- MUST mantener `build()` puro, sin side effects.
- MUST minimizar rebuilds: extraer subarboles y usar selectores/escucha fina.
- SHOULD usar `const` widgets para reducir trabajo de render.

## Layout y adaptabilidad
- MUST evitar tamanos hardcodeados no justificados.
- MUST soportar diferentes anchos de pantalla.
- MUST validar overflow de texto y widgets en pantallas pequenas.

## Accesibilidad minima
- MUST exponer etiquetas semanticas en acciones criticas.
- MUST respetar area tactil minima para controles interactivos.
- MUST NOT depender solo de color para comunicar estado.

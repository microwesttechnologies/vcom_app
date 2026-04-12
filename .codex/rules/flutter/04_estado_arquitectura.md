# Reglas de Estado y Arquitectura

## Capas
- MUST usar capas: `presentation`, `domain`, `data`.
- MUST mantener dependencias hacia adentro: presentation -> domain -> data.
- MUST NOT importar `data` directamente desde widgets.

## ViewModel / Controller
- MUST concentrar casos de uso de pantalla en ViewModel/Controller.
- MUST exponer estado inmutable para la UI.
- MUST modelar estado con tipos claros (`loading`, `success`, `error`).

## Dominio
- MUST colocar reglas de negocio en casos de uso/servicios de dominio.
- MUST NOT duplicar reglas de negocio entre UI y repositorio.

## Data layer
- MUST mapear DTOs a modelos de dominio.
- MUST aislar detalles de API, DB y plugins dentro de data sources.
- MUST manejar errores tecnicos y traducirlos a errores de dominio.

## Inyeccion de dependencias
- MUST inyectar dependencias, no crearlas dentro de widgets.
- SHOULD usar providers/constructores para facilitar pruebas.

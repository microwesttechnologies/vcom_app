# Reglas de Performance

## Listas y scroll
- MUST usar constructores lazy (`ListView.builder`, `GridView.builder`) en listas grandes.
- MUST usar item widgets livianos y estables.
- MUST evitar trabajo costoso por item durante scroll.

## Render y animaciones
- MUST evitar repaints innecesarios en zonas estaticas.
- SHOULD usar `RepaintBoundary` solo donde haya evidencia de beneficio.
- MUST limitar animaciones simultaneas costosas.

## CPU y memoria
- MUST mover parsing pesado fuera del hilo de UI cuando sea necesario.
- MUST evitar recrear objetos grandes en cada frame/build.
- MUST revisar fugas por listeners/controllers no liberados.

## Medicion
- MUST medir antes y despues de optimizar.
- MUST registrar metricas minimas de flujos criticos (arranque, lista principal, navegacion).
- MUST NOT aceptar optimizaciones sin evidencia.

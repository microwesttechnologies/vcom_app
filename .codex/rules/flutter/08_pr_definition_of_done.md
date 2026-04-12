# PR Definition of Done (Flutter)

Un PR se considera listo solo si cumple TODO:

1. Arquitectura
- Cambios respetan capas y dependencias.
- No se introducen acoplamientos innecesarios.

2. Codigo
- Formateado y analizado sin issues nuevos.
- Nombres y estructura cumplen reglas de estilo/funciones.

3. Testing
- Tests nuevos/actualizados para cambios funcionales.
- Todos los tests relevantes pasan localmente.

4. UI/UX
- Sin overflow ni regresiones visuales obvias.
- Accesibilidad minima cubierta en cambios de UI.

5. Performance
- Sin degradacion perceptible en flujos criticos.
- Si hubo optimizacion, existe medicion antes/despues.

6. Operacion
- Logs utiles en puntos criticos y sin datos sensibles.
- Manejo de errores validado para casos esperados.

7. SOLID
- SRP: UI, logica de presentacion e infraestructura separadas por responsabilidad.
- OCP: variaciones nuevas agregadas por extension, no por `if/else` masivos.
- LSP: implementaciones sustituyen contratos sin romper consumidores.
- ISP: interfaces pequenas y especificas por caso de uso.
- DIP: dependencias invertidas e inyectadas en modulos de alto nivel.

## Checklist obligatorio para descripcion de PR
```text
[ ] dart format
[ ] flutter analyze
[ ] Analyzer limpio: 0 warnings, 0 info, 0 errors
[ ] flutter test
[ ] Pruebas manuales de flujo principal
[ ] Validacion de accesibilidad basica
[ ] Sin secretos ni datos sensibles en logs
[ ] Cumplimiento SOLID revisado (SRP/OCP/LSP/ISP/DIP)
```

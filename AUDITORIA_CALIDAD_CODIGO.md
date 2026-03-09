# Auditoría de calidad de código (snapshot)

## Alcance y método
Se evaluó el código de la app Flutter (`lib/`) con métricas estáticas y revisión manual de seguridad/mantenibilidad.

Comandos usados:
- `python3` para contar archivos, líneas, `print()`, `TODO/FIXME` y archivos largos.
- `wc -l` para identificar módulos grandes.
- `rg -n` para localizar patrones de logging y seguridad.

## KPI de calidad (baseline actual)

| Área | KPI | Resultado actual | Semáforo | Meta sugerida |
|---|---:|---:|---|---:|
| Mantenibilidad | Archivos > 300 líneas | 18/57 (31.6%) | 🔴 | < 15% |
| Observabilidad segura | Llamadas `print()` en `lib/` | 260 | 🔴 | 0 en producción |
| Higiene técnica | `TODO/FIXME` en `lib/` | 25 | 🟡 | <= 5 |
| Complejidad estructural | Top 5 archivos concentran líneas | 4,379 líneas | 🔴 | dividir por feature |
| Seguridad de datos | Password persistido localmente | Sí (texto plano) | 🔴 | usar storage seguro/cifrado |
| Superficie de ataque móvil | `usesCleartextTraffic=true` | Sí | 🔴 | `false` + network security config |

## Evidencias principales

### 1) Code smells (diseño y mantenibilidad)
1. **Archivos “god file” (muy grandes):**
   - `editProduct.page.dart` (979 líneas), `chat.page.dart` (969), `managerBrand.page.dart` (875), `createProduct.page.dart` (793), `shop.page.dart` (763).
2. **Exceso de logging de depuración en flujos críticos** (creación y carga):
   - `createProduct.component.dart` imprime URL, body y respuestas completas del backend.
3. **Lint de `avoid_print` no activado** en `analysis_options.yaml` (comentado).

### 2) Seguridad
1. **Persistencia de credenciales sensibles en texto plano** con `SharedPreferences`:
   - Se guarda `saved_password` directamente.
2. **Posible exposición de datos sensibles en logs**:
   - Se registran response bodies completos en upload y creación de productos.
3. **Tráfico claro habilitado en Android**:
   - `android:usesCleartextTraffic="true"` incrementa riesgo MITM si se consume HTTP por error/configuración.
4. **Almacenamiento de token solo en memoria singleton**:
   - No hay cifrado persistente ni políticas de rotación/revocación en cliente.

## Indicadores KPI detallados por categoría

### A. KPI de Code Smell
- **SM-1. Ratio de archivos largos** = archivos `>300` líneas / total.
  - Actual: `18/57 = 31.6%`.
- **SM-2. Densidad de logging de depuración** = `print()` / KLOC.
  - Actual aproximado: `260 / 15.6 KLOC = 16.6 prints/KLOC`.
- **SM-3. Concentración de complejidad** = líneas top-5 / líneas auditadas.
  - Actual: `4379 / 15639 = 28.0%`.

### B. KPI de Seguridad
- **SEC-1. Secretos/credenciales en almacenamiento no seguro**.
  - Actual: 1 caso crítico (password en `SharedPreferences`).
- **SEC-2. Endpoints/respuestas sensibles en logs**.
  - Actual: múltiples ocurrencias en componentes de carga y creación.
- **SEC-3. Configuración de red insegura en cliente móvil**.
  - Actual: `usesCleartextTraffic=true` (1 hallazgo crítico).

### C. KPI operativos recomendados (para seguimiento mensual)
- **Tiempo medio de remediación (MTTR) por hallazgo crítico**.
- **% de módulos con lint clean** (sin warnings críticos).
- **% de releases sin logs sensibles** (scan CI sobre `print`, `debugPrint`, tokens/password/body).
- **Cobertura de tests de flujos críticos** (auth, creación de producto, upload).

## Plan de mejora priorizado
1. **Crítico (seguridad):** migrar credenciales/tokens a `flutter_secure_storage` y eliminar password en `SharedPreferences`.
2. **Crítico (seguridad):** deshabilitar `usesCleartextTraffic` y forzar HTTPS/WSS con network security config.
3. **Alto (calidad):** activar reglas de lint estrictas (`avoid_print`, `prefer_final_locals`, etc.) y bloquear CI al incumplir.
4. **Alto (arquitectura):** dividir páginas >700 líneas en widgets y casos de uso por feature.
5. **Medio:** sustituir logs por capa de logging con niveles y redacción de datos sensibles.


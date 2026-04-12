# Reglas de Estilo de Codigo

## Nomenclatura
- MUST usar `UpperCamelCase` para clases, enums, typedefs.
- MUST usar `lowerCamelCase` para variables, metodos y parametros.
- MUST usar nombres semanticos por intencion, no por tipo (`userRepository`, no `repo1`).
- MUST NOT usar abreviaciones opacas (`tmp`, `obj`, `data2`) salvo alcance local trivial.

## Estructura de archivos
- MUST mantener un archivo por responsabilidad principal.
- MUST mantener imports ordenados: SDK, paquetes, proyecto.
- MUST NOT dejar imports sin uso.
- SHOULD mantener archivos por debajo de 400 lineas; si supera, dividir por responsabilidad.

## Legibilidad
- MUST preferir codigo explicito sobre magia implicita.
- MUST mantener funciones cortas (objetivo: <= 40 lineas).
- MUST evitar anidacion profunda (maximo recomendado: 3 niveles).
- MUST agregar comentario breve solo cuando la logica no sea evidente.

## Constancia y null-safety
- MUST usar `const` donde aplique.
- MUST usar tipos no-null por defecto.
- MUST evitar `!` (null assertion) salvo cuando exista garantia documentada en ese punto.

## Prohibiciones de estilo
- MUST NOT usar `print` en codigo de app. Usar logger central.
- MUST NOT comentar bloques muertos; eliminar codigo no usado.
- MUST NOT mezclar idioma en nombres publicos de API.

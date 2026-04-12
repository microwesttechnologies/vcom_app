# Reglas SOLID para Flutter (VCOM)

Objetivo: aplicar SOLID de forma practica en `pages`, `components` y `core`.

## S - Single Responsibility Principle (SRP)
Una clase/modulo debe tener una sola razon de cambio.

- MUST mantener `*.page.dart` enfocado en UI y navegacion.
- MUST mantener `*.component.dart` enfocado en estado y orquestacion de la pantalla.
- MUST mantener `*.service.dart` o `*.gateway.dart` enfocados en IO e integraciones.
- MUST NOT mezclar en una misma clase: render, reglas de negocio, acceso HTTP y persistencia.
- SHOULD dividir clases cuando crezcan por cambios de distinta naturaleza (UI vs negocio vs infraestructura).

Criterio SRP rapido:
- Si una clase cambia por motivos de diseno visual y tambien por cambios de API, esta violando SRP.

## O - Open/Closed Principle (OCP)
El codigo debe abrirse a extension sin modificar comportamiento estable existente.

- MUST extender comportamiento mediante nuevas clases/estrategias, no con `if/else` gigantes por tipo.
- SHOULD usar abstracciones para casos variables (p. ej. politicas de validacion, estrategias de filtro, mapeadores).
- MUST NOT editar flujo estable para agregar un nuevo proveedor cuando puede agregarse una implementacion nueva.
- SHOULD preferir composicion sobre herencia profunda.

Criterio OCP rapido:
- Agregar una variacion funcional debe requerir agregar archivo/clase nueva, no tocar multiples modulos estables.

## L - Liskov Substitution Principle (LSP)
Una implementacion concreta debe poder sustituir su contrato sin romper consumidores.

- MUST respetar contratos de interfaces/clases base (tipos, errores esperados, invariantes).
- MUST NOT fortalecer precondiciones en subclases.
- MUST NOT debilitar postcondiciones en subclases.
- MUST mantener semantica consistente en metodos override.
- SHOULD crear tests de contrato para implementaciones alternativas (fake/mock/real).

Criterio LSP rapido:
- Si una implementacion obliga a consumidores a agregar casos especiales, hay riesgo de violacion LSP.

## I - Interface Segregation Principle (ISP)
Los consumidores no deben depender de metodos que no usan.

- MUST crear interfaces pequenas por caso de uso.
- MUST NOT definir interfaces monoliticas tipo `AppService` con metodos no relacionados.
- SHOULD separar interfaces de lectura/escritura cuando los clientes no necesiten ambas.
- SHOULD exponer contratos minimos desde `core` hacia `components`.

Criterio ISP rapido:
- Si una clase implementa una interfaz y deja metodos vacios o `throw UnimplementedError`, la interfaz esta mal segmentada.

## D - Dependency Inversion Principle (DIP)
Los modulos de alto nivel dependen de abstracciones, no de detalles concretos.

- MUST inyectar dependencias por constructor o provider.
- MUST depender de interfaces/contratos en `components` y casos de uso.
- MUST encapsular detalles concretos (HTTP client, storage, plugin) en `core`.
- MUST NOT instanciar servicios concretos dentro de widgets cuando pueda inyectarse.
- SHOULD definir adaptadores para desacoplar librerias externas.

Criterio DIP rapido:
- Si cambiar la libreria de red obliga a cambiar UI/componentes, se esta violando DIP.

## Reglas transversales de aplicacion
- MUST aplicar SOLID de forma pragmatica: evitar sobre-ingenieria en features pequenas.
- MUST justificar excepciones SOLID en descripcion de PR cuando haya tradeoff intencional.
- SHOULD refactorizar por pasos pequenos guiados por tests.

## Checklist SOLID para PR
- [ ] SRP: cada clase tiene una sola razon de cambio.
- [ ] OCP: nuevas variaciones se agregan por extension y no por condicionamiento masivo.
- [ ] LSP: implementaciones cumplen contrato sin casos especiales en consumidores.
- [ ] ISP: interfaces pequenas, sin metodos irrelevantes para clientes.
- [ ] DIP: modulos de alto nivel dependen de abstracciones e inyeccion.

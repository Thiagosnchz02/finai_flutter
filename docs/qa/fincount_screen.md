# QA Notes - Fincount Screen

## Visual updates
- Ajustado el color base del `Scaffold` y aplicado un gradiente vertical más aireado para reducir el contraste duro inicial y dar más respiro al contenido.
- Incrementadas las transparencias de tarjetas e iconos para mejorar la separación de elementos sin sacrificar la legibilidad de la lista.

## Interacciones
- Se añadió `RefreshIndicator` con `AlwaysScrollableScrollPhysics` para permitir la recarga manual incluso cuando la lista es corta.

## Accesibilidad
- Revisado contraste del texto clave en tarjetas (blanco y opacidades ≥0.65 sobre fondo #0B1120/#15243B). Cumple ratio AA para texto de 14 px+ según [WCAG contrast checker](https://webaim.org/resources/contrastchecker/).
- Aumentado el tamaño de la tipografía secundaria de 13 px a 14 px para mejorar legibilidad.

## Flujos verificados
- Inspección de código confirma que las rutas de alta/edición/borrado de planes siguen apuntando a `PlanDetailsScreen` y `AddPlanScreen`; no se modificaron llamadas.
- Lógica de filtros por importe/categoría/fecha no forma parte de este módulo (`FincountService` conserva firma original); sin regresiones detectadas.
- Cálculo y etiqueta de balance "Para gastar" no se altera en este cambio (la lógica permanece en `_getBalanceLabel`).

## Pruebas
- No se pudieron ejecutar pruebas manuales ni automatizadas en este entorno. Se recomienda verificación manual en dispositivo real para confirmar animaciones de refresco y contraste en pantallas OLED.

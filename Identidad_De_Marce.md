# Kit de Identidad de Marca: Aurora

Guía Maestra de Estilo para la Aplicación FinAiVersión: 1.0
Fecha: 11 de junio de 2025

Este documento define la identidad visual de la aplicación FinAi, basada en el concepto Aurora. Es la guía de referencia final para el diseño, desarrollo y comunicación de la marca, asegurando coherencia, sofisticación y una experiencia de usuario excepcional.

*

### 1. Concepto de Marca: Aurora

La identidad Aurora se inspira en la belleza orgánica y la inteligencia fluida de una aurora boreal. La visión es una fusión entre una estética eléctrica y moderna con un enfoque en la sofisticación y la claridad. No se trata de un brillo estridente, sino de una luz controlada y elegante que se mueve sobre un fondo profundo, guiando al usuario de forma intuitiva.

El concepto encapsula la dualidad de la app:

* Tecnológica y Precisa: La base oscura y la tipografía nítida transmiten seguridad, confianza y la precisión de la IA que impulsa FinAi.
* Humana y Orgánica: Los gradientes suaves y el efecto de vidrio (_glassmorphism_) crean una experiencia inmersiva, tranquila y menos intimidante que la de la banca tradicional.

> La esencia de Aurora es "luz inteligente": una guía visual que simplifica la complejidad financiera, generando calma y control en el usuario.

*

### 2. Paleta de Colores Final

La paleta ha sido ajustada para ser sofisticada y legible, atenuando el brillo excesivo. Los colores vibrantes se usan como acentos estratégicos sobre una base oscura y neutra.

#### Colores Primarios y de Base

Son el fundamento de la interfaz, creando el ambiente _premium_ y oscuro característico de Aurora.

| Muestra                                                            | Nombre del Color     | Uso Principal                                                             | HEX       | RGB           | CMYK          |
| ------------------------------------------------------------------ | -------------------- | ------------------------------------------------------------------------- | --------- | ------------- | ------------- |
| ![#141418](https://via.placeholder.com/20/141418?text=+ "#141418") | Grafito Profundo | Fondos principales de la app.                                             | `#141418` | 20, 20, 24    | 17, 17, 0, 91 |
| ![#9927FD](https://via.placeholder.com/20/9927FD?text=+ "#9927FD") | Púrpura Aurora   | Botones de acción principal (CTA), estados activos, acentos clave.    | `#9927FD` | 153, 39, 253  | 40, 85, 0, 1  |
| ![#1E1DFF](https://via.placeholder.com/20/1E1DFF?text=+ "#1E1DFF") | Azul Eléctrico   | Parte final de gradientes, gráficos de datos, íconos de alta importancia. | `#1E1DFF` | 30, 29, 255   | 88, 89, 0, 0  |
| ![#FFFFFF](https://via.placeholder.com/20/FFFFFF?text=+ "#FFFFFF") | Blanco Puro      | Texto principal, contenido de alta visibilidad.                           | `#FFFFFF` | 255, 255, 255 | 0, 0, 0, 0    |
| ![#A0AEC0](https://via.placeholder.com/20/A0AEC0?text=+ "#A0AEC0") | Gris Neutro      | Texto secundario, captions, bordes sutiles.                               | `#A0AEC0` | 160, 174, 192 | 17, 9, 0, 25  |

#### Colores Semánticos (Estados y Notificaciones)

Se usan para comunicar éxito, advertencia o error de forma universal. Han sido seleccionados para mantener la armonía visual.

| Muestra                                                            | Nombre del Color   | Uso Principal                                 | HEX       | RGB          | CMYK          |
| ------------------------------------------------------------------ | ------------------ | --------------------------------------------- | --------- | ------------ | ------------- |
| ![#25C9A4](https://via.placeholder.com/20/25C9A4?text=+ "#25C9A4") | Verde Digital  | Éxito, confirmaciones, valores positivos.     | `#25C9A4` | 37, 201, 164 | 82, 0, 18, 21 |
| ![#FFB800](https://via.placeholder.com/20/FFB800?text=+ "#FFB800") | Ámbar Moderado | Advertencias, estados pendientes.             | `#FFB800` | 255, 184, 0  | 0, 28, 100, 0 |
| ![#E5484D](https://via.placeholder.com/20/E5484D?text=+ "#E5484D") | Rojo Sobrio    | Errores, alertas críticas, valores negativos. | `#E5484D` | 229, 72, 77  | 0, 69, 66, 10 |

*

### 3. Tipografía

Se ha seleccionado una única familia tipográfica, Inter, por su excepcional legibilidad en pantallas, su versatilidad en distintos pesos y su estética moderna y neutra, ideal para una aplicación fintech.

* Familia Tipográfica: Inter
* Fuente de Obtención: Google Fonts

| Uso                                     | Peso (Weight) | Tamaño (Ejemplo) | Espaciado (Letras) |
| --------------------------------------- | ------------- | ---------------- | ------------------ |
| Encabezado H1 (Títulos de pantalla) | Bold      | 32px             | -1%                |
| Encabezado H2 (Títulos de sección)  | SemiBold  | 24px             | 0%                 |
| Encabezado H3 (Subtítulos)          | Medium    | 20px             | 0%                 |
| Cuerpo de Texto (Párrafos, Items)   | Regular       | 16px             | +0.5%              |
| Botones                             | SemiBold  | 16px             | 0%                 |
| Caption (Microcopy, Metadatos)      | Regular       | 12px             | +1%                |

```
// Ejemplo de uso en CSS
h1 {
  font-family: 'Inter', sans-serif;
  font-weight: 700;
  font-size: 32px;
}

p {
  font-family: 'Inter', sans-serif;
  font-weight: 400;
  font-size: 16px;
}
```

*

### 4. Componentes de UI y Reglas de Uso

Esta sección define cómo aplicar la identidad visual a los componentes clave para asegurar una experiencia de usuario coherente y pulida.

#### Botones

La regla principal es la simplicidad y la claridad. Todos los botones de acción deben usar el color Púrpura Aurora (`#9927FD`) para crear una jerarquía de acción inconfundible.

| Tipo de Botón            | Apariencia Visual                                                                                                                   | Reglas de Uso                                                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Botón Primario (CTA) | ![#9927FD](https://via.placeholder.com/150x40/9927FD/FFFFFF?text=Acción+Principal "#9927FD")                                        | Fondo sólido en `Púrpura Aurora` con texto en `Blanco Puro`. Se utiliza para la acción más importante de una pantalla (Ej: "Enviar", "Ahorrar"). |
| Botón Secundario     | ![#141418](https://via.placeholder.com/150x40/141418/9927FD?text=Acción+Secundaria\&fontColor=9927FD\&borderColor=9927FD "#141418") | Borde de 1px en `Púrpura Aurora` y texto en `Púrpura Aurora` sobre un fondo transparente o del color base. Para acciones alternativas.           |
| Botón de Texto       | Acción de Texto                                                                                                                 | Sin fondo ni borde. El texto es de color `Púrpura Aurora`. Para acciones de baja prioridad o dentro de texto (Ej: "Ver todo").                       |

#### Tarjetas (Glassmorphism)

Las tarjetas son el principal contenedor de información. Su efecto de vidrio esmerilado sobre un fondo dinámico es clave en la estética Aurora.

* Fondo: Un relleno semi-transparente del color base.

```css
background: rgba(26, 26, 26, 0.55); // Matiz ligeramente más claro que el fondo
```

* Desenfoque (Blur): Aplica un desenfoque al contenido que está detrás de la tarjeta.

```css
backdrop-filter: blur(20px);
-webkit-backdrop-filter: blur(20px);
```

* Borde: Un borde muy sutil, casi imperceptible, para definir los límites de la tarjeta.

```css
border: 1px solid rgba(255, 255, 255, 0.1);
```

#### Gráficos y Visualización de Datos

Los gráficos deben ser limpios y fáciles de interpretar.

* Gráficos Lineales: Utilizar el gradiente de `Púrpura Aurora` a `Azul Eléctrico` para representar datos en evolución.
* Gráficos de Barra/Anillo: Usar el `Púrpura Aurora` o el `Verde Digital` para indicar progreso o valores positivos. El `Rojo Sobrio` se reserva para valores negativos o déficits.

*

### 5. Iconografía

El estilo de los iconos debe ser coherente con la modernidad y limpieza de la marca.

* Estilo: Lineal (outline). Evitar iconos rellenos (solid) para la navegación principal.
* Peso del Trazo: Consistente, preferiblemente entre 1.5px y 2px.
* Esquinas: Ligeramente redondeadas para una apariencia más suave y moderna.
* Color: Los iconos deben usar `Gris Neutro` (`#A0AEC0`) por defecto, y `Púrpura Aurora` (`#9927FD`) o `Blanco Puro` para indicar un estado activo o seleccionado.

Referencia estilística: La librería Feather Icons es un excelente punto de partida para el estilo deseado.

*

### 6. Guía de 'Qué Evitar'

Para mantener la integridad y sofisticación de la marca Aurora, es crucial evitar ciertos estilos que diluirían su impacto.

| ✅ Correcto (Do)                                                                                      | ❌ Incorrecto (Don't)                                                                                                                     |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| Usar botones de un solo color sólido (`#9927FD`) para las acciones principales.              | Usar gradientes, sombras o múltiples colores en los botones. Reduce la claridad de la acción.                                                |
| Aplicar efectos de brillo sutiles _detrás_ de las tarjetas de vidrio para crear profundidad. | Añadir un `glow` o resplandor neón directamente sobre los textos, iconos o botones. Resulta estridente y poco profesional.                   |
| Mantener un alto contraste entre texto y fondo (Blanco sobre Grafito).                               | Usar colores de texto de bajo contraste (ej. gris oscuro sobre negro) que comprometen la legibilidad y accesibilidad.                        |
| Utilizar la paleta de colores de forma contenida, principalmente para datos y estados.               | Saturar la interfaz con demasiados colores a la vez. El Púrpura y el Azul deben dominar sutilmente.                                          |
| Emplear el efecto de _glassmorphism_ de forma consistente en todas las tarjetas.             | Mezclar estilos, como usar tarjetas de vidrio junto a otras con sombras de caja (`box-shadow`) marcadas, lo cual rompe la coherencia visual. |
| Seguir una iconografía lineal y limpia con un peso de trazo consistente.                             | Mezclar estilos de iconos (lineal, relleno, duotono) o usar iconos con una estética lúdica o de videojuego.                                  |

​

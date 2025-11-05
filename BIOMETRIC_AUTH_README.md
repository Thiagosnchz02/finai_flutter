# Configuración de Autenticación Biométrica

## 📋 Pasos para Implementar

### 1. Ejecutar Migración de Base de Datos

Antes de usar la funcionalidad, necesitas agregar el campo `biometric_auth_enabled` a la tabla `profiles` en Supabase:

1. Ve a tu proyecto de Supabase
2. Navega a **SQL Editor**
3. Copia y ejecuta el contenido del archivo `supabase_migration_biometric.sql`

```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS biometric_auth_enabled BOOLEAN DEFAULT false;
```

### 2. Reconstruir la Aplicación

Después de los cambios en el código nativo de Android, necesitas reconstruir la app:

```bash
flutter clean
flutter pub get
flutter run
```

## 🎯 Cómo Funciona

### Para el Usuario:

1. **Habilitar la Huella Digital:**
   - Iniciar sesión normalmente con email y contraseña (primera vez)
   - Ir a **Configuración** en la app
   - Buscar la sección **Seguridad**
   - Activar el toggle **"Inicio de Sesión con Huella"**
   - El sistema pedirá confirmar la identidad con la huella
   - Una vez confirmado, la autenticación biométrica estará habilitada

2. **Usar la Huella para Iniciar Sesión:**
   - El botón **"Iniciar sesión con huella"** siempre está visible en el login (si el dispositivo tiene sensor)
   - Al tocar el botón, se abrirá el diálogo de autenticación biométrica
   - Colocar el dedo en el sensor de huella
   - **Casos posibles:**
     - ✅ Si tienes sesión guardada Y la opción habilitada → Acceso directo al dashboard
     - ⚠️ Si tienes sesión pero NO has habilitado la opción → Mensaje para ir a Configuración
     - ⚠️ Si NO tienes sesión guardada → Mensaje para iniciar sesión primero con email/contraseña

3. **Deshabilitar la Huella Digital:**
   - Ir a **Configuración > Seguridad**
   - Desactivar el toggle **"Inicio de Sesión con Huella"**
   - Confirmar la deshabilitación
   - El botón seguirá visible en login, pero pedirá habilitar la opción al usarlo

## 🔧 Cambios Técnicos Realizados

### Archivos Modificados:

1. **MainActivity.kt** - Cambio de `FlutterActivity` a `FlutterFragmentActivity`
2. **AndroidManifest.xml** - Permisos biométricos agregados
3. **Profile Model** - Campo `biometricAuthEnabled` agregado
4. **Settings Service** - Métodos para gestionar autenticación biométrica
5. **Settings Screen** - UI para activar/desactivar la huella
6. **Login Screen** - Lógica para mostrar botón solo si está habilitado
7. **App Events** - Evento `settingsBiometricToggled` para tracking

### Flujo de Autenticación:

```
Primera vez:
Usuario inicia sesión con email/contraseña
    ↓
Va a Configuración → Seguridad
    ↓
Activa "Inicio de Sesión con Huella"
    ↓
Se verifica soporte del dispositivo
    ↓
Se solicita autenticación biométrica
    ↓
Se guarda en la BD (biometric_auth_enabled = true)
    ↓
Cierra sesión

Siguientes veces:
Usuario ve botón de huella en login (siempre visible)
    ↓
Toca el botón de huella
    ↓
Sistema verifica autenticación biométrica
    ↓
Verifica si hay sesión guardada
    ↓
Verifica si tiene la opción habilitada
    ↓
Si todo OK → Dashboard 🎉
Si no → Mensaje apropiado según el caso
```

## ⚠️ Requisitos

- Dispositivo Android con sensor de huella o Face ID
- Supabase configurado correctamente
- Sesión activa de Supabase para que funcione la autenticación biométrica

## 🐛 Solución de Problemas

**Problema:** El botón de huella no aparece en login
- **Solución:** Verifica que tu dispositivo tenga sensor de huella configurado en el sistema operativo

**Problema:** "Debes habilitar la opción en Configuración"
- **Solución:** Ve a Configuración → Seguridad y activa "Inicio de Sesión con Huella"

**Problema:** "Primero debes iniciar sesión con tu email y contraseña"
- **Solución:** No hay sesión guardada. Inicia sesión normalmente primero, luego habilita la opción en Configuración

**Problema:** Error "PlatformException no_fragment_activity"
- **Solución:** Asegúrate de haber cambiado `FlutterActivity` a `FlutterFragmentActivity` en MainActivity.kt y reconstruido la app

**Problema:** "Este dispositivo no soporta autenticación biométrica"
- **Solución:** El dispositivo no tiene sensor de huella o no está configurado en el sistema

## 📱 Experiencia de Usuario

La autenticación biométrica funciona igual que en apps bancarias modernas como:
- Imagin
- Trade Republic
- N26
- Revolut

El usuario tiene control total sobre cuándo habilitar/deshabilitar esta funcionalidad.

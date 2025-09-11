# finai_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuración de variables de entorno

Copia el archivo `.env.example` como `.env` y reemplaza los valores de ejemplo
por tus credenciales reales:

```
cp .env.example .env
```

Variables requeridas:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Configuración de Supabase Auth

Asegúrate de incluir `io.supabase.finai://login-callback/` en **Redirect URLs** dentro de los ajustes de autenticación de Supabase para habilitar el deep linking en la aplicación.

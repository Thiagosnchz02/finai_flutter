-- Migración para agregar el campo de autenticación biométrica
-- Ejecutar este SQL en el editor SQL de Supabase

-- Agregar la columna biometric_auth_enabled a la tabla profiles
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS biometric_auth_enabled BOOLEAN DEFAULT false;

-- Comentario para documentación
COMMENT ON COLUMN profiles.biometric_auth_enabled IS 'Indica si el usuario tiene habilitada la autenticación biométrica para inicio de sesión';

-- Opcional: Actualizar los perfiles existentes (por defecto false)
UPDATE profiles 
SET biometric_auth_enabled = false 
WHERE biometric_auth_enabled IS NULL;

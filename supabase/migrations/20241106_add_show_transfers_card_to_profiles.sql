-- Agregar columna para configurar visibilidad de tarjeta de traspasos
-- Opciones: 'never' (nunca), 'auto' (solo cuando hay traspasos), 'always' (siempre)
ALTER TABLE profiles 
ADD COLUMN show_transfers_card TEXT NOT NULL DEFAULT 'never' 
CHECK (show_transfers_card IN ('never', 'auto', 'always'));

COMMENT ON COLUMN profiles.show_transfers_card IS 'Configura cuándo mostrar la tarjeta de traspasos: never (nunca), auto (solo con traspasos), always (siempre)';

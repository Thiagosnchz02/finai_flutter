-- Añadir campo swipe_month_navigation a la tabla profiles
-- Este campo controla si el usuario puede deslizar para navegar entre meses en la pantalla de transacciones

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS swipe_month_navigation BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.swipe_month_navigation IS 'Habilita navegación por swipe entre meses en la pantalla de transacciones';

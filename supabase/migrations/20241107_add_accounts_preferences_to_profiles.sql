-- Añadir campos de preferencias de cuentas a la tabla profiles
-- Controlan la visualización y comportamiento de las tarjetas de cuentas

-- Modo de vista: 'compact' muestra solo icono+título+saldo; 'context' añade tags y categoría
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS accounts_view_mode TEXT NOT NULL DEFAULT 'compact';

-- Activar/desactivar animaciones avanzadas (blur, bounce, gradiente)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS accounts_advanced_animations BOOLEAN NOT NULL DEFAULT true;

-- Mostrar mini-gráfico sparkline en tarjetas
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS show_account_sparkline BOOLEAN NOT NULL DEFAULT false;

-- Comentarios descriptivos
COMMENT ON COLUMN public.profiles.accounts_view_mode IS 'Modo de visualización de tarjetas de cuentas: compact (mínimo) o context (con detalles)';
COMMENT ON COLUMN public.profiles.accounts_advanced_animations IS 'Habilita animaciones avanzadas (blur, bounce, gradientes)';
COMMENT ON COLUMN public.profiles.show_account_sparkline IS 'Muestra mini-gráfico sparkline en tarjetas de cuentas';

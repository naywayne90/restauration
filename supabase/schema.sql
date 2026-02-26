-- ============================================================================
-- MILY'S Gourmet — Schéma PostgreSQL complet pour Supabase
-- Application SaaS de restauration d'entreprise — Abidjan, Côte d'Ivoire
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 2. TYPES ENUM (idempotents)
-- ============================================================================
DO $$ BEGIN CREATE TYPE employee_type_enum AS ENUM (
    'regular','intern','guard','walk_in'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE user_role_enum AS ENUM (
    'superadmin','milys_admin','milys_kitchen','milys_logistics',
    'milys_cashier','company_admin','company_cashier',
    'third_party_cashier','employee'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE stock_movement_enum AS ENUM (
    'entry','exit','adjustment','waste','return'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN CREATE TYPE po_status_enum AS ENUM (
    'draft','ordered','partial','received','cancelled'
); EXCEPTION WHEN duplicate_object THEN NULL; END $$;


-- ============================================================================
-- 3. TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 Entreprises
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS companies (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    slug          TEXT UNIQUE NOT NULL,
    logo_url      TEXT,
    industry      TEXT,
    address       TEXT,
    city          TEXT NOT NULL DEFAULT 'Abidjan',
    contact_name  TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS company_sites (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id            UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name                  TEXT NOT NULL,
    address               TEXT NOT NULL,
    city                  TEXT NOT NULL DEFAULT 'Abidjan',
    latitude              DECIMAL(10,8),
    longitude             DECIMAL(11,8),
    capacity_per_day      INTEGER NOT NULL DEFAULT 100,
    delivery_window_start TIME DEFAULT '11:30',
    delivery_window_end   TIME DEFAULT '13:00',
    is_active             BOOLEAN NOT NULL DEFAULT true,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS company_contracts (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id         UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    subsidy_rate       DECIMAL(5,2) NOT NULL DEFAULT 90.00
                           CHECK (subsidy_rate >= 0 AND subsidy_rate <= 100),
    base_meal_price    INTEGER NOT NULL DEFAULT 5000,   -- FCFA prix de référence
    max_meals_per_day  INTEGER NOT NULL DEFAULT 200,
    max_budget_monthly INTEGER,                         -- FCFA, NULL = illimité
    allowed_formulas   TEXT[] NOT NULL DEFAULT ARRAY['standard'],
    working_days       INTEGER NOT NULL DEFAULT 5       -- 5 ou 6 jours ouvrés
                           CHECK (working_days BETWEEN 5 AND 6),
    payment_mode       TEXT NOT NULL DEFAULT 'invoice'
                           CHECK (payment_mode IN ('invoice','tickets')),
    tickets_per_month  INTEGER,                         -- NULL si mode facture
    advance_weeks      INTEGER NOT NULL DEFAULT 2       -- Planification à N semaines
                           CHECK (advance_weeks BETWEEN 1 AND 4),
    start_date         DATE NOT NULL,
    end_date           DATE,
    is_active          BOOLEAN NOT NULL DEFAULT true,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.2 Profils & Rôles
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email         TEXT UNIQUE NOT NULL,
    full_name     TEXT NOT NULL,
    phone         TEXT,
    avatar_url    TEXT,
    employee_type employee_type_enum NOT NULL DEFAULT 'regular',
    matricule     TEXT UNIQUE,
    company_id    UUID REFERENCES companies(id) ON DELETE SET NULL,
    site_id       UUID REFERENCES company_sites(id) ON DELETE SET NULL,
    department    TEXT,
    badge_number  TEXT,
    ticket_balance INTEGER NOT NULL DEFAULT 0,          -- Solde tickets restants
    allergens     TEXT[] DEFAULT '{}',                   -- Allergènes déclarés
    preferences   TEXT[] DEFAULT '{}',                   -- Préférences alimentaires
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_roles (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role       user_role_enum NOT NULL,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    granted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, role)
);

-- ----------------------------------------------------------------------------
-- 3.3 Catalogue — Plats & Ingrédients
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dishes (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 TEXT NOT NULL,
    description          TEXT,
    category             TEXT NOT NULL
                             CHECK (category IN ('ivoirien','international','entree','dessert','boisson','extra')),
    price                INTEGER NOT NULL DEFAULT 0,   -- FCFA prix de vente
    cost_price           INTEGER DEFAULT 0,            -- FCFA coût de revient
    photo_url            TEXT,
    is_available         BOOLEAN NOT NULL DEFAULT true,
    is_starter           BOOLEAN NOT NULL DEFAULT false,
    is_extra             BOOLEAN NOT NULL DEFAULT false,
    preparation_time_min INTEGER DEFAULT 30,
    calories             INTEGER,
    is_vegetarian        BOOLEAN NOT NULL DEFAULT false,
    is_vegan             BOOLEAN NOT NULL DEFAULT false,
    is_featured          BOOLEAN NOT NULL DEFAULT false,
    sort_order           INTEGER DEFAULT 0,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_allergens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id    UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    allergen   TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_ratings (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id    UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating     SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(dish_id, user_id)
);

CREATE TABLE IF NOT EXISTS ingredients (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    unit          TEXT NOT NULL DEFAULT 'kg',
    current_stock DECIMAL(10,3) NOT NULL DEFAULT 0,
    min_stock     DECIMAL(10,3) NOT NULL DEFAULT 0,
    cost_per_unit INTEGER NOT NULL DEFAULT 0,     -- FCFA/unité
    category      TEXT,
    supplier_id   UUID,  -- FK ajoutée après création de suppliers
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_ingredients (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id         UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    ingredient_id   UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity_needed DECIMAL(10,3) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(dish_id, ingredient_id)
);

-- ----------------------------------------------------------------------------
-- 3.4 Fournisseurs & Stock
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL,
    contact_name  TEXT,
    phone         TEXT,
    email         TEXT,
    address       TEXT,
    city          TEXT DEFAULT 'Abidjan',
    is_active     BOOLEAN NOT NULL DEFAULT true,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- FK différée pour ingredients → suppliers
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'ingredients_supplier_id_fkey'
  ) THEN
    ALTER TABLE ingredients
      ADD CONSTRAINT ingredients_supplier_id_fkey
      FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS supplier_ingredients (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id         UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    ingredient_id       UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    supply_price        INTEGER NOT NULL DEFAULT 0,   -- FCFA/unité
    delivery_delay_days INTEGER NOT NULL DEFAULT 1,
    is_preferred        BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(supplier_id, ingredient_id)
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number  TEXT NOT NULL UNIQUE,
    supplier_id   UUID NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    status        po_status_enum NOT NULL DEFAULT 'draft',
    total_amount  INTEGER NOT NULL DEFAULT 0,         -- FCFA
    ordered_by    UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ordered_at    TIMESTAMPTZ,
    expected_at   TIMESTAMPTZ,
    received_at   TIMESTAMPTZ,
    notes         TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    ingredient_id     UUID NOT NULL REFERENCES ingredients(id) ON DELETE RESTRICT,
    qty_ordered       DECIMAL(10,3) NOT NULL,
    qty_received      DECIMAL(10,3) DEFAULT 0,
    unit_price        INTEGER NOT NULL DEFAULT 0,     -- FCFA
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    movement_type stock_movement_enum NOT NULL,
    quantity      DECIMAL(10,3) NOT NULL,
    balance_after DECIMAL(10,3),
    reason        TEXT,
    reference_id  UUID,   -- purchase_order_id ou production_batch_id
    performed_by  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.5 Menus hebdomadaires
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS menus (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name               TEXT NOT NULL,
    week_start         DATE NOT NULL,
    week_end           DATE NOT NULL,
    is_published       BOOLEAN NOT NULL DEFAULT false,
    selection_deadline TIMESTAMPTZ,                     -- Date limite de sélection (J-3 avant premier jour)
    published_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes              TEXT,
    created_by         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(week_start)
);

CREATE TABLE IF NOT EXISTS menu_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id      UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    dish_id      UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    day_of_week  INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 6),  -- 1=Lun…6=Sam
    is_starter   BOOLEAN NOT NULL DEFAULT false,
    sort_order   INTEGER DEFAULT 0,
    max_quantity INTEGER,       -- NULL = illimité
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(menu_id, dish_id, day_of_week)
);

-- ----------------------------------------------------------------------------
-- 3.6 Planning hebdomadaire employé
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS weekly_plans (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    menu_id     UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    status      TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft','confirmed','locked')),
    locked_at   TIMESTAMPTZ,                           -- Date de verrouillage global
    confirmed_at TIMESTAMPTZ,                          -- Date de validation par l'employé
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, menu_id)
);

CREATE TABLE IF NOT EXISTS weekly_plan_items (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    day_of_week    INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 6),
    dish_id        UUID NOT NULL REFERENCES dishes(id) ON DELETE RESTRICT,
    extras         JSONB NOT NULL DEFAULT '[]',        -- [{dish_id, quantity, unit_price}]
    is_locked      BOOLEAN NOT NULL DEFAULT false,     -- Verrouillé à J-3
    locked_at      TIMESTAMPTZ,                        -- Quand le jour a été verrouillé
    is_cancelled   BOOLEAN NOT NULL DEFAULT false,
    cancel_reason  TEXT,                               -- Raison obligatoire si annulé
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(weekly_plan_id, day_of_week)
);

-- ----------------------------------------------------------------------------
-- 3.7 Commandes
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    dish_id        UUID NOT NULL REFERENCES dishes(id) ON DELETE RESTRICT,
    site_id        UUID REFERENCES company_sites(id) ON DELETE SET NULL,
    order_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    extras         JSONB NOT NULL DEFAULT '[]',
    status         TEXT NOT NULL DEFAULT 'confirmed'
                       CHECK (status IN ('confirmed','served','no_show','cancelled')),
    total_price    INTEGER NOT NULL DEFAULT 0,    -- FCFA total
    company_share  INTEGER NOT NULL DEFAULT 0,    -- part entreprise FCFA
    employee_share INTEGER NOT NULL DEFAULT 0,    -- part employé FCFA
    ticket_used    BOOLEAN NOT NULL DEFAULT false,   -- Payé par ticket physique ?
    special_instructions TEXT,
    served_at      TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, order_date)
);

-- ----------------------------------------------------------------------------
-- 3.8 QR Codes & Scans
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qr_codes (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    code       TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),
    is_used    BOOLEAN NOT NULL DEFAULT false,
    expires_at TIMESTAMPTZ NOT NULL,
    scanned_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    scanned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS qr_scans (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_code_id UUID NOT NULL REFERENCES qr_codes(id) ON DELETE CASCADE,
    scanned_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
    site_id    UUID REFERENCES company_sites(id) ON DELETE SET NULL,
    scan_type  TEXT NOT NULL CHECK (scan_type IN ('qr','manual','ticket')),
    result     TEXT NOT NULL CHECK (result IN ('success','already_used','expired','not_found')),
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes      TEXT
);

-- ----------------------------------------------------------------------------
-- 3.9 Tickets physiques
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS physical_tickets (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id    UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    ticket_number TEXT NOT NULL UNIQUE,
    is_used       BOOLEAN NOT NULL DEFAULT false,
    used_by       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    used_at       TIMESTAMPTZ,
    order_id      UUID REFERENCES orders(id) ON DELETE SET NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.10 Production
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_batches (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    production_date   DATE NOT NULL,
    site_id           UUID NOT NULL REFERENCES company_sites(id),
    dish_id           UUID NOT NULL REFERENCES dishes(id),
    planned_quantity  INTEGER NOT NULL,
    produced_quantity INTEGER DEFAULT 0,
    status            TEXT DEFAULT 'planned'
                          CHECK (status IN ('planned','in_progress','completed')),
    stock_deducted    BOOLEAN DEFAULT false,
    created_at        TIMESTAMPTZ DEFAULT now(),
    UNIQUE(production_date, site_id, dish_id)
);

-- ----------------------------------------------------------------------------
-- 3.11 Livraisons
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drivers (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name    TEXT NOT NULL,
    phone        TEXT NOT NULL,
    vehicle_info TEXT,
    is_active    BOOLEAN DEFAULT true,
    created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS deliveries (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_date  DATE NOT NULL,
    site_id        UUID NOT NULL REFERENCES company_sites(id),
    driver_id      UUID REFERENCES drivers(id),
    status         TEXT DEFAULT 'scheduled'
                       CHECK (status IN ('scheduled','in_transit','delivered','failed')),
    departure_time TIMESTAMPTZ,
    arrival_time   TIMESTAMPTZ,
    notes          TEXT,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS delivery_items (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_id       UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    dish_id           UUID NOT NULL REFERENCES dishes(id),
    quantity          INTEGER NOT NULL,
    received_quantity INTEGER DEFAULT 0
);

-- ----------------------------------------------------------------------------
-- 3.12 Formules
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS formulas (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    base_price  INTEGER NOT NULL DEFAULT 5000,
    description TEXT,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.13 Facturation & Paiements
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id     UUID NOT NULL REFERENCES companies(id),
    invoice_number TEXT UNIQUE NOT NULL,
    period_start   DATE NOT NULL,
    period_end     DATE NOT NULL,
    total_amount   INTEGER NOT NULL DEFAULT 0,
    total_meals    INTEGER DEFAULT 0,
    status         TEXT DEFAULT 'draft'
                       CHECK (status IN ('draft','sent','paid','overdue','cancelled')),
    due_date       DATE,
    sent_at        TIMESTAMPTZ,
    paid_at        TIMESTAMPTZ,
    pdf_url        TEXT,
    notes          TEXT,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id  UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity    INTEGER NOT NULL,
    unit_price  INTEGER NOT NULL,
    total       INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS invoice_employee_details (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id    UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    employee_id   UUID NOT NULL REFERENCES auth.users(id),
    employee_name TEXT NOT NULL,
    total_meals   INTEGER NOT NULL,
    total_amount  INTEGER NOT NULL,
    extras_amount INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS payments (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID REFERENCES auth.users(id),
    company_id     UUID REFERENCES companies(id),
    amount         INTEGER NOT NULL,
    payment_method TEXT NOT NULL
                       CHECK (payment_method IN ('salary_deduction','orange_money','wave','mtn_money','djamo','cash','ticket','bank_transfer')),
    reference      TEXT,
    status         TEXT DEFAULT 'pending'
                       CHECK (status IN ('pending','completed','failed','refunded')),
    payment_type   TEXT DEFAULT 'employee'
                       CHECK (payment_type IN ('employee','company','walk_in')),
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_payments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    payment_id UUID NOT NULL REFERENCES payments(id),
    amount     INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.14 Notifications
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    message    TEXT NOT NULL,
    type       TEXT DEFAULT 'info'
                   CHECK (type IN ('info','success','warning','error')),
    is_read    BOOLEAN DEFAULT false,
    link       TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 3.15 Audit & Config
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID REFERENCES auth.users(id),
    action     TEXT NOT NULL,
    table_name TEXT,
    record_id  UUID,
    old_data   JSONB,
    new_data   JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS app_config (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key         TEXT UNIQUE NOT NULL,
    value       JSONB NOT NULL,
    description TEXT,
    updated_at  TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- 4. INDEX
-- ============================================================================

-- companies
CREATE INDEX IF NOT EXISTS idx_companies_slug      ON companies(slug);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON companies(is_active);

-- company_sites
CREATE INDEX IF NOT EXISTS idx_sites_company_id    ON company_sites(company_id);
CREATE INDEX IF NOT EXISTS idx_sites_is_active     ON company_sites(is_active);

-- company_contracts
CREATE INDEX IF NOT EXISTS idx_contracts_company_id ON company_contracts(company_id);
CREATE INDEX IF NOT EXISTS idx_contracts_is_active  ON company_contracts(is_active);

-- profiles
CREATE INDEX IF NOT EXISTS idx_profiles_email         ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id    ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_site_id       ON profiles(site_id);
CREATE INDEX IF NOT EXISTS idx_profiles_matricule     ON profiles(matricule);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active     ON profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_profiles_employee_type ON profiles(employee_type);

-- user_roles
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id    ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_company_id ON user_roles(company_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role       ON user_roles(role);

-- dishes
CREATE INDEX IF NOT EXISTS idx_dishes_category    ON dishes(category);
CREATE INDEX IF NOT EXISTS idx_dishes_is_available ON dishes(is_available);
CREATE INDEX IF NOT EXISTS idx_dishes_is_featured  ON dishes(is_featured);

-- ingredients
CREATE INDEX IF NOT EXISTS idx_ingredients_supplier  ON ingredients(supplier_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_is_active ON ingredients(is_active);

-- stock_movements
CREATE INDEX IF NOT EXISTS idx_stock_mvt_ingredient ON stock_movements(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_stock_mvt_created_at ON stock_movements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_mvt_type       ON stock_movements(movement_type);

-- purchase_orders
CREATE INDEX IF NOT EXISTS idx_po_supplier_id  ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_po_order_number ON purchase_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_po_status       ON purchase_orders(status);

-- menus
CREATE INDEX IF NOT EXISTS idx_menus_week_start   ON menus(week_start);
CREATE INDEX IF NOT EXISTS idx_menus_week_end     ON menus(week_end);
CREATE INDEX IF NOT EXISTS idx_menus_is_published ON menus(is_published);

-- menu_items
CREATE INDEX IF NOT EXISTS idx_menu_items_menu_id    ON menu_items(menu_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_dish_id    ON menu_items(dish_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_day        ON menu_items(day_of_week);

-- weekly_plans
CREATE INDEX IF NOT EXISTS idx_weekly_plans_user_id ON weekly_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_menu_id ON weekly_plans(menu_id);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_status  ON weekly_plans(status);

-- weekly_plan_items
CREATE INDEX IF NOT EXISTS idx_wpi_weekly_plan_id ON weekly_plan_items(weekly_plan_id);
CREATE INDEX IF NOT EXISTS idx_wpi_dish_id        ON weekly_plan_items(dish_id);

-- orders
CREATE INDEX IF NOT EXISTS idx_orders_user_id    ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_dish_id    ON orders(dish_id);
CREATE INDEX IF NOT EXISTS idx_orders_site_id    ON orders(site_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status     ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_date_status ON orders(order_date, status);

-- qr_codes
CREATE INDEX IF NOT EXISTS idx_qr_codes_user_id  ON qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_order_id ON qr_codes(order_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_code     ON qr_codes(code);
CREATE INDEX IF NOT EXISTS idx_qr_codes_is_used  ON qr_codes(is_used);

-- qr_scans
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON qr_scans(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_at ON qr_scans(scanned_at DESC);

-- production_batches
CREATE INDEX IF NOT EXISTS idx_prod_date    ON production_batches(production_date DESC);
CREATE INDEX IF NOT EXISTS idx_prod_site_id ON production_batches(site_id);
CREATE INDEX IF NOT EXISTS idx_prod_dish_id ON production_batches(dish_id);
CREATE INDEX IF NOT EXISTS idx_prod_status  ON production_batches(status);

-- deliveries
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_site_id   ON deliveries(site_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_date      ON deliveries(delivery_date DESC);
CREATE INDEX IF NOT EXISTS idx_deliveries_status    ON deliveries(status);

-- delivery_items
CREATE INDEX IF NOT EXISTS idx_deliv_items_delivery ON delivery_items(delivery_id);
CREATE INDEX IF NOT EXISTS idx_deliv_items_dish     ON delivery_items(dish_id);

-- invoices
CREATE INDEX IF NOT EXISTS idx_invoices_company_id ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status     ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_period     ON invoices(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date   ON invoices(due_date);

-- payments
CREATE INDEX IF NOT EXISTS idx_payments_user_id    ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_company_id ON payments(company_id);
CREATE INDEX IF NOT EXISTS idx_payments_status     ON payments(status);

-- invoice_payments
CREATE INDEX IF NOT EXISTS idx_inv_pay_invoice_id ON invoice_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_inv_pay_payment_id ON invoice_payments(payment_id);

-- notifications
CREATE INDEX IF NOT EXISTS idx_notif_user_id    ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notif_is_read    ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notif_created_at ON notifications(created_at DESC);

-- audit_logs
CREATE INDEX IF NOT EXISTS idx_audit_user_id    ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_table_name ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_created_at ON audit_logs(created_at DESC);

-- ============================================================================
-- 5. FONCTIONS & TRIGGERS
-- ============================================================================

-- --------------------------------------------------------------------------
-- 5.1 updated_at automatique
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN
    SELECT unnest(ARRAY[
      'companies','company_sites','company_contracts',
      'profiles','dishes','ingredients',
      'suppliers','purchase_orders','menus',
      'weekly_plans','orders'
    ])
  LOOP
    EXECUTE format(
      'CREATE OR REPLACE TRIGGER trg_%s_updated_at
       BEFORE UPDATE ON %I
       FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
      tbl, tbl
    );
  END LOOP;
END;
$$;

-- --------------------------------------------------------------------------
-- 5.2 Trigger audit pour tables critiques
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data)
  VALUES (
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    CASE TG_OP WHEN 'DELETE' THEN OLD.id ELSE NEW.id END,
    CASE TG_OP WHEN 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE TG_OP WHEN 'DELETE' THEN NULL ELSE to_jsonb(NEW) END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY['orders','invoices','payments','deliveries']) LOOP
    EXECUTE format(
      'CREATE OR REPLACE TRIGGER trg_%s_audit
       AFTER INSERT OR UPDATE OR DELETE ON %I
       FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn()',
      tbl, tbl
    );
  END LOOP;
END;
$$;

-- --------------------------------------------------------------------------
-- 5.3 Calcul automatique des parts (subvention entreprise / part employé)
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION compute_order_shares()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_subsidy DECIMAL(5,2) := 0;
BEGIN
  SELECT cc.subsidy_rate INTO v_subsidy
  FROM profiles p
  JOIN company_contracts cc ON cc.company_id = p.company_id
  WHERE p.id = NEW.user_id
    AND cc.is_active = true
  ORDER BY cc.created_at DESC
  LIMIT 1;

  IF v_subsidy IS NULL THEN v_subsidy := 0; END IF;

  NEW.company_share  := ROUND(NEW.total_price * v_subsidy / 100);
  NEW.employee_share := NEW.total_price - NEW.company_share;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_orders_shares
BEFORE INSERT OR UPDATE OF total_price ON orders
FOR EACH ROW EXECUTE FUNCTION compute_order_shares();

-- --------------------------------------------------------------------------
-- 5.4 Génération automatique du QR code à la création d'une commande
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION generate_qr_on_order()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.status = 'confirmed' THEN
    INSERT INTO qr_codes (user_id, order_id, expires_at)
    VALUES (
      NEW.user_id,
      NEW.id,
      NEW.order_date::TIMESTAMPTZ + INTERVAL '1 day'
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_orders_qr_generate
AFTER INSERT ON orders
FOR EACH ROW EXECUTE FUNCTION generate_qr_on_order();

-- --------------------------------------------------------------------------
-- 5.5 Trigger stock_movement : met à jour ingredients.current_stock
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_ingredient_stock()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_delta DECIMAL(10,3);
  v_new_balance DECIMAL(10,3);
BEGIN
  -- Determine the signed delta based on movement type
  IF NEW.movement_type IN ('entry', 'return') THEN
    v_delta := ABS(NEW.quantity);
  ELSIF NEW.movement_type IN ('exit', 'waste') THEN
    v_delta := -ABS(NEW.quantity);
  ELSE -- 'adjustment' uses the raw value (can be positive or negative)
    v_delta := NEW.quantity;
  END IF;

  UPDATE ingredients
  SET current_stock = current_stock + v_delta
  WHERE id = NEW.ingredient_id
  RETURNING current_stock INTO v_new_balance;

  -- Store the resulting balance in the movement row
  NEW.balance_after := v_new_balance;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_stock_movement_update
BEFORE INSERT ON stock_movements
FOR EACH ROW EXECUTE FUNCTION update_ingredient_stock();

-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Activer RLS sur toutes les tables
DO $$
DECLARE tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'companies','company_sites','company_contracts',
    'profiles','user_roles',
    'dishes','dish_allergens','dish_ratings','ingredients','dish_ingredients',
    'suppliers','supplier_ingredients','purchase_orders','purchase_order_items',
    'stock_movements','menus','menu_items','weekly_plans','weekly_plan_items',
    'orders','qr_codes','qr_scans','physical_tickets',
    'production_batches','drivers','deliveries','delivery_items',
    'formulas','invoices','invoice_items','invoice_employee_details',
    'payments','invoice_payments',
    'notifications','audit_logs','app_config'
  ])
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END;
$$;

-- --------------------------------------------------------------------------
-- Fonctions helper RLS
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION auth_user_id() RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT auth.uid();
$$;

CREATE OR REPLACE FUNCTION has_role(p_role TEXT) RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid() AND role = p_role::user_role_enum
  );
$$;

CREATE OR REPLACE FUNCTION is_milys_staff() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
      AND role IN ('superadmin','milys_admin','milys_kitchen','milys_logistics','milys_cashier')
  );
$$;

CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
      AND role IN ('superadmin','milys_admin')
  );
$$;

CREATE OR REPLACE FUNCTION get_my_company_id() RETURNS UUID
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT company_id FROM profiles WHERE id = auth.uid();
$$;

-- --------------------------------------------------------------------------
-- Politiques RLS
-- --------------------------------------------------------------------------

-- profiles
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT
  USING (id = auth.uid() OR is_milys_staff() OR
         (has_role('company_admin') AND company_id = get_my_company_id()));

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE
  USING (id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "profiles_insert_admin" ON profiles;
CREATE POLICY "profiles_insert_admin" ON profiles FOR INSERT
  WITH CHECK (is_admin());

-- user_roles
DROP POLICY IF EXISTS "user_roles_select" ON user_roles;
CREATE POLICY "user_roles_select" ON user_roles FOR SELECT
  USING (user_id = auth.uid() OR is_admin());

DROP POLICY IF EXISTS "user_roles_manage" ON user_roles;
CREATE POLICY "user_roles_manage" ON user_roles
  USING (is_admin()) WITH CHECK (is_admin());

-- companies
DROP POLICY IF EXISTS "companies_select" ON companies;
CREATE POLICY "companies_select" ON companies FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "companies_manage" ON companies;
CREATE POLICY "companies_manage" ON companies
  USING (is_admin()) WITH CHECK (is_admin());

-- company_sites
DROP POLICY IF EXISTS "sites_select" ON company_sites;
CREATE POLICY "sites_select" ON company_sites FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "sites_manage" ON company_sites;
CREATE POLICY "sites_manage" ON company_sites
  USING (is_admin() OR has_role('company_admin'))
  WITH CHECK (is_admin() OR has_role('company_admin'));

-- company_contracts
DROP POLICY IF EXISTS "contracts_select" ON company_contracts;
CREATE POLICY "contracts_select" ON company_contracts FOR SELECT
  USING (is_milys_staff() OR company_id = get_my_company_id());

DROP POLICY IF EXISTS "contracts_manage" ON company_contracts;
CREATE POLICY "contracts_manage" ON company_contracts
  USING (is_admin()) WITH CHECK (is_admin());

-- dishes : lecture pour tous les connectés, écriture admin + cuisine
DROP POLICY IF EXISTS "dishes_select" ON dishes;
CREATE POLICY "dishes_select" ON dishes FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "dishes_manage" ON dishes;
CREATE POLICY "dishes_manage" ON dishes
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- dish_allergens : lecture publique
DROP POLICY IF EXISTS "dish_allergens_select" ON dish_allergens;
CREATE POLICY "dish_allergens_select" ON dish_allergens FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ingredients, stock_movements : staff cuisine + admin
DROP POLICY IF EXISTS "ingredients_select" ON ingredients;
CREATE POLICY "ingredients_select" ON ingredients FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "ingredients_manage" ON ingredients;
CREATE POLICY "ingredients_manage" ON ingredients
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

DROP POLICY IF EXISTS "stock_mvt_select" ON stock_movements;
CREATE POLICY "stock_mvt_select" ON stock_movements FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "stock_mvt_insert" ON stock_movements;
CREATE POLICY "stock_mvt_insert" ON stock_movements FOR INSERT
  WITH CHECK (is_milys_staff());

-- suppliers, supplier_ingredients
DROP POLICY IF EXISTS "suppliers_select" ON suppliers;
CREATE POLICY "suppliers_select" ON suppliers FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "suppliers_manage" ON suppliers;
CREATE POLICY "suppliers_manage" ON suppliers
  USING (is_admin()) WITH CHECK (is_admin());

-- purchase_orders
DROP POLICY IF EXISTS "po_select" ON purchase_orders;
CREATE POLICY "po_select" ON purchase_orders FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "po_manage" ON purchase_orders;
CREATE POLICY "po_manage" ON purchase_orders
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- menus : lecture (publié) + admin publie
DROP POLICY IF EXISTS "menus_select" ON menus;
CREATE POLICY "menus_select" ON menus FOR SELECT
  USING (auth.uid() IS NOT NULL AND (is_published = true OR is_milys_staff()));

DROP POLICY IF EXISTS "menus_manage" ON menus;
CREATE POLICY "menus_manage" ON menus
  USING (is_admin()) WITH CHECK (is_admin());

-- menu_items
DROP POLICY IF EXISTS "menu_items_select" ON menu_items;
CREATE POLICY "menu_items_select" ON menu_items FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "menu_items_manage" ON menu_items;
CREATE POLICY "menu_items_manage" ON menu_items
  USING (is_admin()) WITH CHECK (is_admin());

-- weekly_plans : employé gère ses plans
DROP POLICY IF EXISTS "weekly_plans_select" ON weekly_plans;
CREATE POLICY "weekly_plans_select" ON weekly_plans FOR SELECT
  USING (user_id = auth.uid() OR is_milys_staff() OR has_role('company_admin'));

DROP POLICY IF EXISTS "weekly_plans_manage" ON weekly_plans;
CREATE POLICY "weekly_plans_manage" ON weekly_plans
  USING (user_id = auth.uid() OR is_milys_staff())
  WITH CHECK (user_id = auth.uid() OR is_milys_staff());

-- weekly_plan_items
DROP POLICY IF EXISTS "weekly_plan_items_select" ON weekly_plan_items;
CREATE POLICY "weekly_plan_items_select" ON weekly_plan_items FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM weekly_plans wp
      WHERE wp.id = weekly_plan_items.weekly_plan_id
        AND (wp.user_id = auth.uid() OR is_milys_staff())
    )
  );

DROP POLICY IF EXISTS "weekly_plan_items_manage" ON weekly_plan_items;
CREATE POLICY "weekly_plan_items_manage" ON weekly_plan_items
  USING (
    EXISTS (
      SELECT 1 FROM weekly_plans wp
      WHERE wp.id = weekly_plan_items.weekly_plan_id
        AND wp.user_id = auth.uid()
    ) OR is_milys_staff()
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM weekly_plans wp
      WHERE wp.id = weekly_plan_items.weekly_plan_id
        AND wp.user_id = auth.uid()
    ) OR is_milys_staff()
  );

-- orders : employé voit ses commandes, admin/caissier voient tout
DROP POLICY IF EXISTS "orders_select_own" ON orders;
CREATE POLICY "orders_select_own" ON orders FOR SELECT
  USING (
    user_id = auth.uid()
    OR is_milys_staff()
    OR (has_role('company_admin') AND EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = orders.user_id AND p.company_id = get_my_company_id()
    ))
  );

DROP POLICY IF EXISTS "orders_insert_own" ON orders;
CREATE POLICY "orders_insert_own" ON orders FOR INSERT
  WITH CHECK (user_id = auth.uid() OR is_milys_staff());

DROP POLICY IF EXISTS "orders_update" ON orders;
CREATE POLICY "orders_update" ON orders FOR UPDATE
  USING (user_id = auth.uid() OR is_milys_staff()
         OR has_role('milys_cashier') OR has_role('company_cashier'));

-- qr_codes : employé voit ses QR, caissiers peuvent les consulter
DROP POLICY IF EXISTS "qr_codes_select" ON qr_codes;
CREATE POLICY "qr_codes_select" ON qr_codes FOR SELECT
  USING (user_id = auth.uid() OR is_milys_staff() OR has_role('company_cashier'));

DROP POLICY IF EXISTS "qr_codes_update" ON qr_codes;
CREATE POLICY "qr_codes_update" ON qr_codes FOR UPDATE
  USING (is_milys_staff() OR has_role('milys_cashier') OR has_role('company_cashier'));

-- qr_scans
DROP POLICY IF EXISTS "qr_scans_select" ON qr_scans;
CREATE POLICY "qr_scans_select" ON qr_scans FOR SELECT
  USING (is_milys_staff() OR has_role('company_cashier'));

DROP POLICY IF EXISTS "qr_scans_insert" ON qr_scans;
CREATE POLICY "qr_scans_insert" ON qr_scans FOR INSERT
  WITH CHECK (is_milys_staff() OR has_role('milys_cashier') OR has_role('company_cashier'));

-- production_batches
DROP POLICY IF EXISTS "prod_select" ON production_batches;
CREATE POLICY "prod_select" ON production_batches FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "prod_manage" ON production_batches;
CREATE POLICY "prod_manage" ON production_batches
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- deliveries
DROP POLICY IF EXISTS "deliveries_select" ON deliveries;
CREATE POLICY "deliveries_select" ON deliveries FOR SELECT
  USING (is_milys_staff() OR has_role('company_admin'));

DROP POLICY IF EXISTS "deliveries_manage" ON deliveries;
CREATE POLICY "deliveries_manage" ON deliveries
  USING (is_milys_staff()) WITH CHECK (is_milys_staff());

-- formulas : lecture authentifiée, gestion admin
DROP POLICY IF EXISTS "formulas_select" ON formulas;
CREATE POLICY "formulas_select" ON formulas FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "formulas_manage" ON formulas;
CREATE POLICY "formulas_manage" ON formulas
  USING (is_admin()) WITH CHECK (is_admin());

-- invoices
DROP POLICY IF EXISTS "invoices_select" ON invoices;
CREATE POLICY "invoices_select" ON invoices FOR SELECT
  USING (is_milys_staff() OR company_id = get_my_company_id());

DROP POLICY IF EXISTS "invoices_manage" ON invoices;
CREATE POLICY "invoices_manage" ON invoices
  USING (is_admin()) WITH CHECK (is_admin());

-- payments
DROP POLICY IF EXISTS "payments_select" ON payments;
CREATE POLICY "payments_select" ON payments FOR SELECT
  USING (
    user_id = auth.uid()
    OR is_milys_staff()
    OR (company_id IS NOT NULL AND company_id = get_my_company_id())
  );

DROP POLICY IF EXISTS "payments_insert" ON payments;
CREATE POLICY "payments_insert" ON payments FOR INSERT
  WITH CHECK (user_id = auth.uid() OR is_milys_staff());

DROP POLICY IF EXISTS "payments_manage" ON payments;
CREATE POLICY "payments_manage" ON payments FOR UPDATE
  USING (is_admin() OR is_milys_staff());

-- invoice_payments
DROP POLICY IF EXISTS "inv_pay_select" ON invoice_payments;
CREATE POLICY "inv_pay_select" ON invoice_payments FOR SELECT
  USING (is_milys_staff() OR EXISTS (
    SELECT 1 FROM invoices i
    WHERE i.id = invoice_payments.invoice_id AND i.company_id = get_my_company_id()
  ));

DROP POLICY IF EXISTS "inv_pay_manage" ON invoice_payments;
CREATE POLICY "inv_pay_manage" ON invoice_payments
  USING (is_admin()) WITH CHECK (is_admin());

-- notifications : propres à l'utilisateur
DROP POLICY IF EXISTS "notif_select_own" ON notifications;
CREATE POLICY "notif_select_own" ON notifications FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notif_update_own" ON notifications;
CREATE POLICY "notif_update_own" ON notifications FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notif_insert" ON notifications;
CREATE POLICY "notif_insert" ON notifications FOR INSERT
  WITH CHECK (is_milys_staff());

-- app_config
DROP POLICY IF EXISTS "app_config_select" ON app_config;
CREATE POLICY "app_config_select" ON app_config FOR SELECT
  USING (is_admin());

DROP POLICY IF EXISTS "app_config_manage" ON app_config;
CREATE POLICY "app_config_manage" ON app_config
  USING (has_role('superadmin')) WITH CHECK (has_role('superadmin'));

-- dish_allergens : gestion admin + cuisine
DROP POLICY IF EXISTS "dish_allergens_manage" ON dish_allergens;
CREATE POLICY "dish_allergens_manage" ON dish_allergens
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- dish_ratings : lecture staff, insert/update propre à l'utilisateur
DROP POLICY IF EXISTS "dish_ratings_select" ON dish_ratings;
CREATE POLICY "dish_ratings_select" ON dish_ratings FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "dish_ratings_manage" ON dish_ratings;
CREATE POLICY "dish_ratings_manage" ON dish_ratings
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- dish_ingredients : lecture staff cuisine/admin, gestion admin + cuisine
DROP POLICY IF EXISTS "dish_ingredients_select" ON dish_ingredients;
CREATE POLICY "dish_ingredients_select" ON dish_ingredients FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "dish_ingredients_manage" ON dish_ingredients;
CREATE POLICY "dish_ingredients_manage" ON dish_ingredients
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- supplier_ingredients : lecture staff, gestion admin
DROP POLICY IF EXISTS "supplier_ingredients_select" ON supplier_ingredients;
CREATE POLICY "supplier_ingredients_select" ON supplier_ingredients FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "supplier_ingredients_manage" ON supplier_ingredients;
CREATE POLICY "supplier_ingredients_manage" ON supplier_ingredients
  USING (is_admin()) WITH CHECK (is_admin());

-- purchase_order_items : lecture staff, gestion admin + cuisine
DROP POLICY IF EXISTS "po_items_select" ON purchase_order_items;
CREATE POLICY "po_items_select" ON purchase_order_items FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "po_items_manage" ON purchase_order_items;
CREATE POLICY "po_items_manage" ON purchase_order_items
  USING (is_admin() OR has_role('milys_kitchen'))
  WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- physical_tickets : lecture staff + company_admin, gestion staff
DROP POLICY IF EXISTS "physical_tickets_select" ON physical_tickets;
CREATE POLICY "physical_tickets_select" ON physical_tickets FOR SELECT
  USING (is_milys_staff() OR (has_role('company_admin') AND company_id = get_my_company_id()));

DROP POLICY IF EXISTS "physical_tickets_manage" ON physical_tickets;
CREATE POLICY "physical_tickets_manage" ON physical_tickets
  USING (is_milys_staff()) WITH CHECK (is_milys_staff());

-- drivers : lecture staff, gestion admin + logistique
DROP POLICY IF EXISTS "drivers_select" ON drivers;
CREATE POLICY "drivers_select" ON drivers FOR SELECT
  USING (is_milys_staff());

DROP POLICY IF EXISTS "drivers_manage" ON drivers;
CREATE POLICY "drivers_manage" ON drivers
  USING (is_admin() OR has_role('milys_logistics'))
  WITH CHECK (is_admin() OR has_role('milys_logistics'));

-- delivery_items : lecture staff + company_admin, gestion staff
DROP POLICY IF EXISTS "delivery_items_select" ON delivery_items;
CREATE POLICY "delivery_items_select" ON delivery_items FOR SELECT
  USING (is_milys_staff() OR has_role('company_admin'));

DROP POLICY IF EXISTS "delivery_items_manage" ON delivery_items;
CREATE POLICY "delivery_items_manage" ON delivery_items
  USING (is_milys_staff()) WITH CHECK (is_milys_staff());

-- invoice_items : lecture staff + company_admin pour sa propre entreprise
DROP POLICY IF EXISTS "invoice_items_select" ON invoice_items;
CREATE POLICY "invoice_items_select" ON invoice_items FOR SELECT
  USING (is_milys_staff() OR EXISTS (
    SELECT 1 FROM invoices i
    WHERE i.id = invoice_items.invoice_id AND i.company_id = get_my_company_id()
  ));

DROP POLICY IF EXISTS "invoice_items_manage" ON invoice_items;
CREATE POLICY "invoice_items_manage" ON invoice_items
  USING (is_admin()) WITH CHECK (is_admin());

-- invoice_employee_details : lecture staff + company_admin
DROP POLICY IF EXISTS "inv_emp_details_select" ON invoice_employee_details;
CREATE POLICY "inv_emp_details_select" ON invoice_employee_details FOR SELECT
  USING (is_milys_staff() OR EXISTS (
    SELECT 1 FROM invoices i
    WHERE i.id = invoice_employee_details.invoice_id AND i.company_id = get_my_company_id()
  ));

DROP POLICY IF EXISTS "inv_emp_details_manage" ON invoice_employee_details;
CREATE POLICY "inv_emp_details_manage" ON invoice_employee_details
  USING (is_admin()) WITH CHECK (is_admin());

-- audit_logs : lecture admin uniquement
DROP POLICY IF EXISTS "audit_logs_select" ON audit_logs;
CREATE POLICY "audit_logs_select" ON audit_logs FOR SELECT
  USING (is_admin());

-- ============================================================================
-- 7. SEED DATA — MILY'S Gourmet, Abidjan (Côte d'Ivoire)
-- ============================================================================

-- --------------------------------------------------------------------------
-- 7.1 Entreprises
-- --------------------------------------------------------------------------
INSERT INTO companies (id, name, slug, industry, address, city, contact_name, contact_email, contact_phone, is_active)
VALUES
  ('11111111-0000-0000-0000-000000000001',
   'Orange Côte d''Ivoire', 'orange-ci',
   'Télécommunications',
   'Bd du Général de Gaulle, Plateau', 'Abidjan',
   'Koffi Asante', 'koffi.asante@orange.ci', '+225 07 07 00 01 01', true),

  ('11111111-0000-0000-0000-000000000002',
   'TotalEnergies CI', 'totalenergies-ci',
   'Énergie',
   'Av. Christiani, Marcory', 'Abidjan',
   'Awa Coulibaly', 'awa.coulibaly@totalenergies.com', '+225 07 07 00 02 02', true),

  ('11111111-0000-0000-0000-000000000003',
   'SGBCI — Société Générale', 'sgbci',
   'Banque & Finance',
   'Bd de la République, Plateau', 'Abidjan',
   'Jean-Paul Ahui', 'jpahui@sgbci.ci', '+225 07 07 00 03 03', true)
ON CONFLICT (slug) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.2 Sites (2 par entreprise)
-- --------------------------------------------------------------------------
INSERT INTO company_sites (id, company_id, name, address, city, capacity_per_day, is_active)
VALUES
  ('22222222-0000-0000-0000-000000000001',
   '11111111-0000-0000-0000-000000000001',
   'Orange CI — Siège Plateau', 'Bd du Général de Gaulle, Plateau', 'Abidjan', 350, true),

  ('22222222-0000-0000-0000-000000000002',
   '11111111-0000-0000-0000-000000000001',
   'Orange CI — Cocody', 'Av. Franchet d''Esperey, Cocody', 'Abidjan', 180, true),

  ('22222222-0000-0000-0000-000000000003',
   '11111111-0000-0000-0000-000000000002',
   'TotalEnergies — Marcory', 'Av. Christiani, Marcory', 'Abidjan', 200, true),

  ('22222222-0000-0000-0000-000000000004',
   '11111111-0000-0000-0000-000000000002',
   'TotalEnergies — Zone 4', 'Zone 4, Treichville', 'Abidjan', 120, true),

  ('22222222-0000-0000-0000-000000000005',
   '11111111-0000-0000-0000-000000000003',
   'SGBCI — Plateau', 'Bd de la République, Plateau', 'Abidjan', 250, true),

  ('22222222-0000-0000-0000-000000000006',
   '11111111-0000-0000-0000-000000000003',
   'SGBCI — Yopougon', 'Av. Principal, Yopougon', 'Abidjan', 150, true)
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.3 Contrats
-- --------------------------------------------------------------------------
INSERT INTO company_contracts (company_id, subsidy_rate, base_meal_price, max_meals_per_day, allowed_formulas, start_date, is_active)
VALUES
  ('11111111-0000-0000-0000-000000000001', 90.00, 3500, 530, ARRAY['standard','premium','vegetarien'], '2025-01-01', true),
  ('11111111-0000-0000-0000-000000000002', 85.00, 4500, 320, ARRAY['standard','premium'],               '2025-03-01', true),
  ('11111111-0000-0000-0000-000000000003', 80.00, 3000, 400, ARRAY['standard','vegetarien'],             '2025-06-01', true)
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4 Plats ivoiriens, entrées, desserts, boissons
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  -- Plats ivoiriens
  ('33333333-0000-0000-0000-000000000001', 'Attiéké Poulet Grillé',
   'Semoule de manioc fermentée accompagnée de poulet grillé mariné aux épices locales',
   'ivoirien', 3000, 1200, true, true, false, false),

  ('33333333-0000-0000-0000-000000000002', 'Poulet DG',
   'Poulet Directeur Général : poulet sauté avec banane plantain, carottes et poivrons',
   'ivoirien', 4500, 1800, true, true, false, false),

  ('33333333-0000-0000-0000-000000000003', 'Kedjenou de Poulet',
   'Poulet mijoté à l''étouffée avec légumes, piment et épices dans une canari',
   'ivoirien', 4000, 1600, true, false, false, false),

  ('33333333-0000-0000-0000-000000000004', 'Foutou Sauce Graine',
   'Foutou de banane ou d''igname accompagné de sauce graine (noix de palme)',
   'ivoirien', 3500, 1400, true, true, false, false),

  ('33333333-0000-0000-0000-000000000005', 'Riz Sauce Tomate Poisson',
   'Riz blanc cuit, sauce tomate maison avec poisson fumé ou frais',
   'ivoirien', 2500, 900, true, false, false, false),

  ('33333333-0000-0000-0000-000000000006', 'Garba (Attiéké + Thon)',
   'Attiéké accompagné de thon frit, oignons, piment et salade',
   'ivoirien', 1500, 600, true, true, false, false),

  ('33333333-0000-0000-0000-000000000007', 'Alloco Omelette',
   'Banane plantain frite accompagnée d''omelette aux oignons et tomates',
   'ivoirien', 1800, 700, true, false, false, false),

  ('33333333-0000-0000-0000-000000000008', 'Sauce Gombo + Riz',
   'Soupe gombo aux fruits de mer servie avec riz blanc',
   'ivoirien', 3000, 1100, true, false, false, false),

  ('33333333-0000-0000-0000-000000000009', 'Placali Sauce Arachide',
   'Pâte de manioc fermentée accompagnée de sauce arachide au poulet',
   'ivoirien', 2500, 950, true, false, false, false),

  ('33333333-0000-0000-0000-000000000010', 'Riz Djoumblé (Riz gras)',
   'Riz cuit dans une sauce épicée avec viande et légumes à l''ivoirienne',
   'ivoirien', 3000, 1100, true, false, false, false),

  ('33333333-0000-0000-0000-000000000011', 'Tilapia Braisé + Attiéké',
   'Poisson tilapia grillé au charbon, mariné, servi avec attiéké et piment',
   'ivoirien', 3500, 1400, true, true, false, false),

  -- Entrées
  ('33333333-0000-0000-0000-000000000012', 'Salade Composée',
   'Salade verte, tomates, carottes, avocat, avec vinaigrette maison',
   'entree', 1500, 500, true, false, true, false),

  ('33333333-0000-0000-0000-000000000013', 'Beignets Haricots',
   'Galettes de haricots frites, traditionnelles du petit-déjeuner ivoirien',
   'entree', 500, 200, true, false, true, false),

  -- Desserts
  ('33333333-0000-0000-0000-000000000014', 'Gâteau Ananas',
   'Gâteau moelleux à l''ananas frais de Côte d''Ivoire',
   'dessert', 800, 300, true, false, false, false),

  -- Boissons (is_extra = true car commandables en supplément)
  ('33333333-0000-0000-0000-000000000015', 'Bissap Maison',
   'Jus de fleurs d''hibiscus sucré à la menthe, servi frais',
   'boisson', 500, 150, true, false, false, true)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4b Catalogue complet — Entrées (42 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-1000-0000-0000-000000000001', 'Salade César',
   'Laitue romaine, croûtons, parmesan, sauce César maison',
   'entree', 1800, 650, true, true, true, false),
  ('33333333-1000-0000-0000-000000000002', 'Salade Niçoise',
   'Salade composée, thon, œufs, olives, haricots verts, tomates',
   'entree', 2000, 750, true, false, true, false),
  ('33333333-1000-0000-0000-000000000003', 'Salade de gésiers confits et ses croûtons',
   'Gésiers de volaille confits, salade verte, croûtons dorés',
   'entree', 2200, 900, true, true, true, false),
  ('33333333-1000-0000-0000-000000000004', 'Salade de foie de volaille et sauce citronnée',
   'Foie de volaille poêlé, mesclun, vinaigrette au citron',
   'entree', 2200, 900, true, false, true, false),
  ('33333333-1000-0000-0000-000000000005', 'Salade du Chef',
   'Salade mixte, jambon, fromage, œuf, tomates, concombres',
   'entree', 2000, 800, true, true, true, false),
  ('33333333-1000-0000-0000-000000000006', 'Salade Grecque',
   'Tomates, concombres, poivrons, oignons, olives, feta',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000007', 'Farandole de crudités',
   'Assortiment de légumes crus de saison, sauce au choix',
   'entree', 1500, 500, true, false, true, false),
  ('33333333-1000-0000-0000-000000000008', 'Salade de carottes Thaï',
   'Carottes râpées, sauce thaï, cacahuètes, coriandre',
   'entree', 1500, 550, true, false, true, false),
  ('33333333-1000-0000-0000-000000000009', 'Salade de poulet croustillant épicé',
   'Poulet pané croustillant, salade verte, sauce épicée',
   'entree', 2500, 1000, true, true, true, false),
  ('33333333-1000-0000-0000-000000000010', 'Œufs Mimosas au Paprika',
   'Œufs durs farcis, mayonnaise, paprika doux',
   'entree', 1200, 400, true, false, true, false),
  ('33333333-1000-0000-0000-000000000011', 'Œufs en cocotte au jambon de dinde',
   'Œufs cuits en cocotte, jambon de dinde, crème',
   'entree', 1500, 550, true, false, true, false),
  ('33333333-1000-0000-0000-000000000012', 'Salade de lentilles au jambon de dinde',
   'Lentilles vertes, jambon de dinde, vinaigrette moutardée',
   'entree', 1800, 600, true, false, true, false),
  ('33333333-1000-0000-0000-000000000013', 'Salade d''avocat à la villageoise',
   'Avocat frais, tomates, oignons, piment, citron vert',
   'entree', 1500, 500, true, false, true, false),
  ('33333333-1000-0000-0000-000000000014', 'Salade d''avocat, crevettes et mangues',
   'Avocat, crevettes sautées, mangue fraîche, vinaigrette exotique',
   'entree', 2500, 1100, true, true, true, false),
  ('33333333-1000-0000-0000-000000000015', 'Salade de bœuf et œufs mollets',
   'Bœuf grillé émincé, œufs mollets, salade mêlée',
   'entree', 2500, 1000, true, false, true, false),
  ('33333333-1000-0000-0000-000000000016', 'Salade Piémontaise',
   'Pommes de terre, tomates, jambon, cornichons, mayonnaise',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000017', 'Salade de maïs, tomate, poivrons et jambon de dinde',
   'Maïs doux, tomates, poivrons, jambon de dinde, vinaigrette',
   'entree', 1500, 550, true, false, true, false),
  ('33333333-1000-0000-0000-000000000018', 'Taboulé',
   'Semoule, tomates, concombre, menthe, persil, citron',
   'entree', 1500, 450, true, false, true, false),
  ('33333333-1000-0000-0000-000000000019', 'Salade d''attiéké à la bassamoise',
   'Attiéké, tomates, oignons, piment, huile, à la façon de Grand-Bassam',
   'entree', 1200, 400, true, false, true, false),
  ('33333333-1000-0000-0000-000000000020', 'Beignets à la sardine',
   'Beignets frits garnis de sardine, oignons et épices',
   'entree', 1000, 350, true, false, true, false),
  ('33333333-1000-0000-0000-000000000021', 'Tomates farcies aux dés de légumes',
   'Tomates évidées, farcies de petits légumes et gratinées',
   'entree', 1500, 500, true, false, true, false),
  ('33333333-1000-0000-0000-000000000022', 'Tarte à la tomate et au thon',
   'Pâte brisée, tomates, thon, moutarde, herbes',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000023', 'Quiche au jambon',
   'Pâte brisée, œufs, crème, jambon, fromage râpé',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000024', 'Tarte aux champignons',
   'Pâte feuilletée, champignons de Paris, crème, persil',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000025', 'Tarte à l''oignon',
   'Pâte brisée, oignons caramélisés, lardons, crème',
   'entree', 1500, 550, true, false, true, false),
  ('33333333-1000-0000-0000-000000000026', 'Salade périgourdine',
   'Salade frisée, gésiers confits, noix, croûtons, vinaigrette',
   'entree', 2200, 850, true, false, true, false),
  ('33333333-1000-0000-0000-000000000027', 'Salade de tomates au pesto',
   'Tomates fraîches, pesto basilic, mozzarella, huile d''olive',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000028', 'Salade asiatique de concombres',
   'Concombres marinés, sauce soja, sésame, gingembre',
   'entree', 1200, 400, true, false, true, false),
  ('33333333-1000-0000-0000-000000000029', 'Salade d''avocat et poulet grillé',
   'Avocat frais, poulet grillé, tomates cerises, roquette',
   'entree', 2500, 950, true, true, true, false),
  ('33333333-1000-0000-0000-000000000030', 'Salade de haricots verts au thon',
   'Haricots verts, thon, œufs durs, oignons, vinaigrette',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000031', 'Salade Lyonnaise',
   'Frisée, lardons, œuf poché, croûtons, vinaigrette tiède',
   'entree', 2000, 800, true, false, true, false),
  ('33333333-1000-0000-0000-000000000032', 'Œufs de Moumar',
   'Œufs préparés à la façon de Moumar, épices locales',
   'entree', 1500, 500, true, false, true, false),
  ('33333333-1000-0000-0000-000000000033', 'Courgettes farcies',
   'Courgettes évidées, farcies de viande hachée et gratinées',
   'entree', 2000, 750, true, false, true, false),
  ('33333333-1000-0000-0000-000000000034', 'Salade de langue de bœuf',
   'Langue de bœuf en tranches, cornichons, vinaigrette',
   'entree', 2500, 1000, true, false, true, false),
  ('33333333-1000-0000-0000-000000000035', 'Quiche aux crevettes',
   'Pâte brisée, crevettes, crème, aneth, fromage',
   'entree', 2200, 900, true, false, true, false),
  ('33333333-1000-0000-0000-000000000036', 'Quiche aux écrevisses',
   'Pâte brisée, écrevisses, crème fraîche, ciboulette',
   'entree', 2500, 1100, true, false, true, false),
  ('33333333-1000-0000-0000-000000000037', 'Quiche lorraine',
   'Pâte brisée, lardons, œufs, crème, fromage',
   'entree', 1800, 650, true, false, true, false),
  ('33333333-1000-0000-0000-000000000038', 'Avocats, pamplemousse et crevettes',
   'Demi-avocat garni de pamplemousse et crevettes, sauce cocktail',
   'entree', 2500, 1000, true, false, true, false),
  ('33333333-1000-0000-0000-000000000039', 'Velouté de courges',
   'Soupe crémeuse de courges, crème fraîche, graines de courge',
   'entree', 1500, 450, true, false, true, false),
  ('33333333-1000-0000-0000-000000000040', 'Salade de concombres à la thaïlandaise',
   'Concombres, sauce thaï sucrée-pimentée, cacahuètes, menthe',
   'entree', 1200, 400, true, false, true, false),
  ('33333333-1000-0000-0000-000000000041', 'Aumônière de crêpes au jambon de dinde',
   'Crêpe farcie au jambon de dinde, béchamel, gratinée',
   'entree', 2000, 750, true, false, true, false),
  ('33333333-1000-0000-0000-000000000042', 'Crêpes roulées au jambon et champignons persillés',
   'Crêpes garnies de jambon, champignons persillés, sauce crème',
   'entree', 2000, 750, true, false, true, false)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4c Catalogue complet — Sauces traditionnelles (31 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-2000-0000-0000-000000000001', 'Sauce djoumgblé',
   'Sauce traditionnelle ivoirienne (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 3000, 1200, true, true, false, false),
  ('33333333-2000-0000-0000-000000000002', 'Sauce gouagouassou',
   'Sauce au gombo sec pilé (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000003', 'Sauce gombo',
   'Sauce à base de gombo frais (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 2500, 1000, true, true, false, false),
  ('33333333-2000-0000-0000-000000000004', 'Sauce Kopê',
   'Sauce ivoirienne à base de graines (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000005', 'Sauce kwala',
   'Sauce traditionnelle aux feuilles (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000006', 'Sauce graine',
   'Sauce à base de noix de palme (viande fumée ou poisson fumé)',
   'ivoirien', 3000, 1200, true, true, false, false),
  ('33333333-2000-0000-0000-000000000007', 'Sauce claire',
   'Bouillon parfumé aux épices (poisson frais ou poisson fumé)',
   'ivoirien', 2500, 900, true, false, false, false),
  ('33333333-2000-0000-0000-000000000008', 'Soumara Lafri',
   'Sauce à base de soumara (graines de néré fermentées)',
   'ivoirien', 2500, 950, true, false, false, false),
  ('33333333-2000-0000-0000-000000000009', 'Soupe du pêcheur',
   'Soupe riche aux fruits de mer : seiche, écrevisses, escargots, poisson',
   'ivoirien', 3500, 1500, true, true, false, false),
  ('33333333-2000-0000-0000-000000000010', 'Sauce Arachide',
   'Sauce à base de pâte d''arachide (viande fumée, poisson fumé ou poulet fumé)',
   'ivoirien', 2800, 1100, true, true, false, false),
  ('33333333-2000-0000-0000-000000000011', 'Sauce Arachide-Dah',
   'Sauce arachide aux feuilles de dah (viande fumée)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000012', 'Sauce pistache',
   'Sauce à base de graines de pistache (viande fumée ou pondeuse)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000013', 'Biokesseu',
   'Spécialité ivoirienne à base de feuilles et de poisson',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000014', 'Sauce N''tro',
   'Sauce ivoirienne épicée (viande fumée ou poisson fumé)',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000015', 'Sauce Akpi',
   'Sauce aux graines d''akpi (viande fumée ou poulet fumé)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000016', 'Akpessi',
   'Plat ivoirien à base d''igname ou banane plantain et poisson',
   'ivoirien', 2500, 950, true, false, false, false),
  ('33333333-2000-0000-0000-000000000017', 'Citrouille de crabes',
   'Citrouille mijotée aux crabes frais, épices locales',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-2000-0000-0000-000000000018', 'Sauce feuille',
   'Sauce aux feuilles vertes (viande fumée, poisson fumé, crevettes, crabes)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000019', 'Kédjénou',
   'Viande ou volaille mijotée à l''étouffée (pondeuse ou poulet fumé)',
   'ivoirien', 3500, 1400, true, true, false, false),
  ('33333333-2000-0000-0000-000000000020', 'Pépésoupe de carpes',
   'Soupe pimentée de carpes fraîches aux épices',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000021', 'Pépésoupe de tripes',
   'Soupe pimentée de tripes de bœuf aux épices',
   'ivoirien', 2500, 1000, true, false, false, false),
  ('33333333-2000-0000-0000-000000000022', 'Kédjénou de pintade au vin rouge',
   'Pintade mijotée à l''étouffée, vin rouge, légumes',
   'ivoirien', 4500, 1800, true, true, false, false),
  ('33333333-2000-0000-0000-000000000023', 'Pépésoupe de pâtes de bœuf',
   'Soupe épicée aux pâtes de bœuf, piment et aromates',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000024', 'Sauce Mafé',
   'Sauce sénégalaise à l''arachide (viande fumée ou poulet fumé)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000025', 'Soupou Kandia',
   'Sauce sénégalaise au gombo (viande fumée, poisson fumé)',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-2000-0000-0000-000000000026', 'Yassa de poulet',
   'Poulet mariné au citron et oignons caramélisés, spécialité sénégalaise',
   'ivoirien', 3500, 1400, true, true, false, false),
  ('33333333-2000-0000-0000-000000000027', 'Yassa de poisson',
   'Poisson mariné au citron et oignons fondants, spécialité sénégalaise',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-2000-0000-0000-000000000028', 'Tchiou boulettes',
   'Boulettes de viande en sauce traditionnelle épicée',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-2000-0000-0000-000000000029', 'Sauce moyo',
   'Sauce à la tomate et oignons (poisson frit)',
   'ivoirien', 2500, 950, true, false, false, false),
  ('33333333-2000-0000-0000-000000000030', 'Sauce tomate au gingembre et gombo',
   'Sauce tomate relevée au gingembre avec gombo (poisson)',
   'ivoirien', 2500, 950, true, false, false, false),
  ('33333333-2000-0000-0000-000000000031', 'Sauce dja',
   'Sauce épicée aux escargots, crevettes et viande',
   'ivoirien', 3500, 1400, true, false, false, false)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4d Catalogue complet — Plats africains (23 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-3000-0000-0000-000000000001', 'Choukouya de poulet',
   'Poulet grillé aux épices, marinade traditionnelle',
   'ivoirien', 3000, 1200, true, true, false, false),
  ('33333333-3000-0000-0000-000000000002', 'Poulet braisé',
   'Poulet mariné et braisé au charbon de bois',
   'ivoirien', 3500, 1400, true, true, false, false),
  ('33333333-3000-0000-0000-000000000003', 'Poulet sauté à l''ivoirienne',
   'Poulet sauté aux oignons, tomates et piments, style ivoirien',
   'ivoirien', 3500, 1300, true, false, false, false),
  ('33333333-3000-0000-0000-000000000004', 'Brochettes de poulet',
   'Poulet mariné en brochettes, grillé aux épices',
   'ivoirien', 2500, 1000, true, false, false, false),
  ('33333333-3000-0000-0000-000000000005', 'Choukouya de porc',
   'Porc grillé aux épices, marinade traditionnelle',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-3000-0000-0000-000000000006', 'Porc braisé',
   'Porc mariné et braisé au charbon de bois',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-3000-0000-0000-000000000007', 'Porc au four',
   'Rôti de porc cuit lentement au four, épices locales',
   'ivoirien', 4000, 1600, true, false, false, false),
  ('33333333-3000-0000-0000-000000000008', 'Poisson fumé braisé',
   'Poisson fumé grillé au charbon, marinade épicée',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-3000-0000-0000-000000000009', 'Djenkoumé',
   'Pâte de maïs togolaise accompagnée de sauce tomate épicée',
   'ivoirien', 2500, 900, true, false, false, false),
  ('33333333-3000-0000-0000-000000000010', 'Feijoada togolaise',
   'Ragoût de haricots rouges à la togolaise, viande et épices',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-3000-0000-0000-000000000011', 'Choukouya de viande de bœuf',
   'Bœuf grillé aux épices, marinade traditionnelle',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-3000-0000-0000-000000000012', 'Jarret de bœuf braisé',
   'Jarret de bœuf mijoté longuement, tendre et parfumé',
   'ivoirien', 4500, 1800, true, true, false, false),
  ('33333333-3000-0000-0000-000000000013', 'Brochettes de Kefta',
   'Viande hachée épicée en brochettes, grillée au charbon',
   'ivoirien', 2800, 1100, true, false, false, false),
  ('33333333-3000-0000-0000-000000000014', 'APF',
   'Attiéké, poisson frit — classique de la cuisine ivoirienne',
   'ivoirien', 2500, 1000, true, true, false, false),
  ('33333333-3000-0000-0000-000000000015', 'Tchep au poulet',
   'Riz au gras sénégalais cuit avec du poulet et des légumes',
   'ivoirien', 3500, 1400, true, true, false, false),
  ('33333333-3000-0000-0000-000000000016', 'Tchep à la viande et aux olives',
   'Thiéboudienne à la viande, olives et légumes',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-3000-0000-0000-000000000017', 'Tchep blanc au poisson',
   'Riz blanc sénégalais au poisson et légumes',
   'ivoirien', 3000, 1200, true, false, false, false),
  ('33333333-3000-0000-0000-000000000018', 'Tchep rouge au poisson',
   'Thiéboudienne rouge au poisson, tomate, légumes',
   'ivoirien', 3500, 1400, true, true, false, false),
  ('33333333-3000-0000-0000-000000000019', 'Vermicelles sénégalaises',
   'Vermicelles au poulet et safran, spécialité sénégalaise',
   'ivoirien', 3000, 1100, true, false, false, false),
  ('33333333-3000-0000-0000-000000000020', 'Couscous sénégalais',
   'Couscous de mil, viande rôtie et sauce oignon',
   'ivoirien', 3500, 1400, true, false, false, false),
  ('33333333-3000-0000-0000-000000000021', 'Tajine de poulet au citron confit',
   'Tajine marocain, poulet, citron confit, olives',
   'ivoirien', 4000, 1600, true, true, false, false),
  ('33333333-3000-0000-0000-000000000022', 'Couscous Royal',
   'Couscous garni de merguez, brochettes, poulet et légumes',
   'ivoirien', 5000, 2000, true, true, false, false),
  ('33333333-3000-0000-0000-000000000023', 'Couscous Marocain',
   'Semoule de couscous, légumes variés, viande, bouillon parfumé',
   'ivoirien', 4500, 1800, true, false, false, false)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4e Catalogue complet — Plats du monde (26 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-4000-0000-0000-000000000001', 'Colombo de porc',
   'Porc mijoté au colombo, pommes de terre, légumes',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000002', 'Rôti de porc',
   'Rôti de porc au four, jus de cuisson, herbes',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000003', 'Mijoté de boulettes de viande',
   'Boulettes de viande hachée mijotées en sauce tomate',
   'international', 3500, 1300, true, false, false, false),
  ('33333333-4000-0000-0000-000000000004', 'Bœuf sauté aux champignons noirs',
   'Emincé de bœuf sauté, champignons noirs, sauce soja',
   'international', 4500, 1800, true, false, false, false),
  ('33333333-4000-0000-0000-000000000005', 'Fricassée de poulet',
   'Poulet mijoté en sauce blanche, champignons, carottes',
   'international', 3500, 1400, true, false, false, false),
  ('33333333-4000-0000-0000-000000000006', 'Poulet aux champignons',
   'Suprême de poulet, sauce crème aux champignons',
   'international', 3500, 1400, true, true, false, false),
  ('33333333-4000-0000-0000-000000000007', 'Poulet chasseur',
   'Poulet mijoté sauce chasseur, tomates, champignons, vin blanc',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000008', 'Hachis parmentier',
   'Purée de pommes de terre gratinée sur viande hachée',
   'international', 3000, 1100, true, false, false, false),
  ('33333333-4000-0000-0000-000000000009', 'Coq au vin et aux champignons',
   'Coq mijoté au vin rouge, lardons, champignons, oignons grelots',
   'international', 5000, 2000, true, true, false, false),
  ('33333333-4000-0000-0000-000000000010', 'Petit pois aux boulettes de viande',
   'Boulettes de viande mijotées avec petits pois en sauce',
   'international', 3000, 1100, true, false, false, false),
  ('33333333-4000-0000-0000-000000000011', 'Haricots rouges au bœuf',
   'Ragoût de haricots rouges et bœuf mijoté',
   'international', 3000, 1200, true, false, false, false),
  ('33333333-4000-0000-0000-000000000012', 'Steak de thon rôti',
   'Pavé de thon snacké, sauce vierge ou soja',
   'international', 5000, 2200, true, true, false, false),
  ('33333333-4000-0000-0000-000000000013', 'Rognons au Calvados',
   'Rognons de veau flambés au Calvados, sauce crème',
   'international', 4500, 1800, true, false, false, false),
  ('33333333-4000-0000-0000-000000000014', 'Poulet rôti et ses petits légumes',
   'Poulet entier rôti au four, légumes de saison',
   'international', 3500, 1400, true, true, false, false),
  ('33333333-4000-0000-0000-000000000015', 'Bœuf stroganoff',
   'Émincé de bœuf, sauce crème, champignons, paprika',
   'international', 4500, 1800, true, false, false, false),
  ('33333333-4000-0000-0000-000000000016', 'Gigot rôti aux fines herbes',
   'Gigot d''agneau rôti, thym, romarin, ail',
   'international', 5500, 2400, true, true, false, false),
  ('33333333-4000-0000-0000-000000000017', 'Poulet farci aux champignons',
   'Poulet farci d''une farce aux champignons, cuit au four',
   'international', 4500, 1800, true, false, false, false),
  ('33333333-4000-0000-0000-000000000018', 'Gratin de pâtes à la viande hachée',
   'Pâtes gratinées, sauce bolognaise, fromage fondu',
   'international', 3000, 1100, true, false, false, false),
  ('33333333-4000-0000-0000-000000000019', 'Boulettes de poulet teriyaki',
   'Boulettes de poulet, sauce teriyaki sucrée-salée, sésame',
   'international', 3500, 1300, true, false, false, false),
  ('33333333-4000-0000-0000-000000000020', 'Poulet pané',
   'Filet de poulet pané croustillant, sauce au choix',
   'international', 3000, 1100, true, false, false, false),
  ('33333333-4000-0000-0000-000000000021', 'Riz aux crevettes et au bœuf',
   'Riz sauté aux crevettes et bœuf, légumes wok',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000022', 'Paella à la sénégalaise',
   'Riz aux fruits de mer et poulet, épices sénégalaises',
   'international', 4500, 1800, true, true, false, false),
  ('33333333-4000-0000-0000-000000000023', 'Escalope de poulet farcie aux champignons',
   'Escalope de poulet farcie de champignons, sauce crème',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000024', 'Poisson papillote',
   'Filet de poisson cuit en papillote, légumes et herbes',
   'international', 4000, 1600, true, false, false, false),
  ('33333333-4000-0000-0000-000000000025', 'Souris d''agneau rôtie au romarin',
   'Souris d''agneau confite au four, romarin, jus corsé',
   'international', 5500, 2400, true, true, false, false),
  ('33333333-4000-0000-0000-000000000026', 'Ragoût d''ignames',
   'Ignames mijotées en sauce avec viande et légumes',
   'international', 3000, 1100, true, false, false, false)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4f Catalogue complet — Accompagnements (20 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-5000-0000-0000-000000000001', 'Riz blanc',
   'Riz blanc nature cuit à la vapeur',
   'extra', 500, 150, true, false, false, true),
  ('33333333-5000-0000-0000-000000000002', 'Foutou',
   'Pâte pilée de banane plantain et manioc',
   'extra', 800, 250, true, false, false, true),
  ('33333333-5000-0000-0000-000000000003', 'Placali',
   'Pâte de manioc fermentée, accompagnement traditionnel',
   'extra', 600, 200, true, false, false, true),
  ('33333333-5000-0000-0000-000000000004', 'Toh',
   'Pâte de maïs ou mil, accompagnement traditionnel',
   'extra', 600, 200, true, false, false, true),
  ('33333333-5000-0000-0000-000000000005', 'Frites de pommes de terre',
   'Pommes de terre frites croustillantes',
   'extra', 800, 300, true, false, false, true),
  ('33333333-5000-0000-0000-000000000006', 'Pommes de terre sautées au persil',
   'Pommes de terre rissolées, persil frais',
   'extra', 800, 300, true, false, false, true),
  ('33333333-5000-0000-0000-000000000007', 'Galettes de pommes de terre',
   'Galettes croustillantes de pommes de terre râpées',
   'extra', 800, 300, true, false, false, true),
  ('33333333-5000-0000-0000-000000000008', 'Croquettes de pomme de terre',
   'Croquettes panées de purée de pommes de terre',
   'extra', 1000, 350, true, false, false, true),
  ('33333333-5000-0000-0000-000000000009', 'Croquettes d''ignames',
   'Croquettes d''igname pilée, frites dorées',
   'extra', 1000, 350, true, false, false, true),
  ('33333333-5000-0000-0000-000000000010', 'Ignames Araignée',
   'Ignames frites en forme d''araignée croustillante',
   'extra', 800, 300, true, false, false, true),
  ('33333333-5000-0000-0000-000000000011', 'Attiéké',
   'Semoule de manioc fermentée, garniture classique ivoirienne',
   'extra', 500, 150, true, false, false, true),
  ('33333333-5000-0000-0000-000000000012', 'Aloco',
   'Banane plantain mûre frite',
   'extra', 800, 250, true, false, false, true),
  ('33333333-5000-0000-0000-000000000013', 'Claclo',
   'Beignets de banane plantain râpée, frits',
   'extra', 800, 250, true, false, false, true),
  ('33333333-5000-0000-0000-000000000014', 'Jardinière de légumes',
   'Assortiment de légumes de saison sautés',
   'extra', 1000, 350, true, false, false, true),
  ('33333333-5000-0000-0000-000000000015', 'Épinards sautés',
   'Épinards frais sautés à l''ail',
   'extra', 800, 300, true, false, false, true),
  ('33333333-5000-0000-0000-000000000016', 'Spaghettis ou autres pâtes',
   'Pâtes cuites al dente, beurre ou sauce au choix',
   'extra', 800, 250, true, false, false, true),
  ('33333333-5000-0000-0000-000000000017', 'Riz au curry',
   'Riz parfumé au curry jaune',
   'extra', 800, 250, true, false, false, true),
  ('33333333-5000-0000-0000-000000000018', 'Riz cantonais',
   'Riz sauté aux légumes, œuf, petits pois',
   'extra', 1200, 450, true, false, false, true),
  ('33333333-5000-0000-0000-000000000019', 'Riz Pilaf au cari et aux légumes',
   'Riz pilaf parfumé au cari, mélange de légumes',
   'extra', 1200, 450, true, false, false, true),
  ('33333333-5000-0000-0000-000000000020', 'Gratin dauphinois',
   'Pommes de terre en fines tranches, crème, fromage gratiné',
   'extra', 1500, 550, true, false, false, true)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4g Catalogue complet — Desserts (31 plats)
-- --------------------------------------------------------------------------
INSERT INTO dishes (id, name, description, category, price, cost_price, is_available, is_featured, is_starter, is_extra)
VALUES
  ('33333333-6000-0000-0000-000000000001', 'Tarte au citron',
   'Pâte sablée, crème au citron, meringue',
   'dessert', 1500, 500, true, false, false, false),
  ('33333333-6000-0000-0000-000000000002', 'Gâteau aux pommes renversées',
   'Gâteau moelleux, pommes caramélisées',
   'dessert', 1500, 500, true, false, false, false),
  ('33333333-6000-0000-0000-000000000003', 'Tarte à l''orange',
   'Pâte sablée, crème à l''orange fraîche',
   'dessert', 1500, 500, true, false, false, false),
  ('33333333-6000-0000-0000-000000000004', 'Moelleux à l''orange',
   'Gâteau fondant parfumé à l''orange',
   'dessert', 1200, 400, true, false, false, false),
  ('33333333-6000-0000-0000-000000000005', 'Beignets aux pommes',
   'Rondelles de pomme en pâte à beignet, cannelle, sucre',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000006', 'Beignets à la banane',
   'Banane en pâte à beignet dorée, sucre glace',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000007', 'Cake au citron et au miel',
   'Cake moelleux parfumé au citron et miel',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000008', 'Cake au chocolat',
   'Cake fondant au chocolat noir',
   'dessert', 1000, 350, true, true, false, false),
  ('33333333-6000-0000-0000-000000000009', 'Cake Marbré',
   'Cake vanille et chocolat marbré',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000010', 'Cake au yaourt',
   'Cake léger au yaourt nature',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000011', 'Cake à la banane',
   'Banana bread moelleux à la banane mûre',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000012', 'Tarte tatin à la mangue',
   'Tarte renversée à la mangue caramélisée',
   'dessert', 1500, 550, true, true, false, false),
  ('33333333-6000-0000-0000-000000000013', 'Gâteau à l''ananas',
   'Gâteau renversé à l''ananas frais caramélisé',
   'dessert', 1200, 400, true, false, false, false),
  ('33333333-6000-0000-0000-000000000014', 'Gâteau roulé à la confiture',
   'Génoise roulée garnie de confiture',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000015', 'Madeleines',
   'Petits gâteaux moelleux en forme de coquillage',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000016', 'Thiopati',
   'Beignets sénégalais sucrés, parfumés à la fleur d''oranger',
   'dessert', 500, 150, true, false, false, false),
  ('33333333-6000-0000-0000-000000000017', 'Beignets de carnaval',
   'Beignets soufflés croustillants, sucre glace',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000018', 'Gbofotos',
   'Beignets ivoiriens sucrés, moelleux et dorés',
   'dessert', 500, 150, true, false, false, false),
  ('33333333-6000-0000-0000-000000000019', 'Yaourt à la façon Mily''s',
   'Yaourt maison crémeux, parfumé selon la recette Mily''s',
   'dessert', 800, 250, true, true, false, false),
  ('33333333-6000-0000-0000-000000000020', 'Thiakry',
   'Couscous de mil sucré au lait caillé, vanille',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000021', 'Brownies aux M&Ms',
   'Brownies fondants au chocolat, éclats de M&Ms',
   'dessert', 1200, 400, true, true, false, false),
  ('33333333-6000-0000-0000-000000000022', 'Mousse au chocolat',
   'Mousse aérienne au chocolat noir',
   'dessert', 1200, 400, true, true, false, false),
  ('33333333-6000-0000-0000-000000000023', 'Éclair au chocolat',
   'Pâte à choux, crème pâtissière chocolat, glaçage',
   'dessert', 1500, 550, true, false, false, false),
  ('33333333-6000-0000-0000-000000000024', 'Chouquettes',
   'Petits choux croustillants au sucre perlé',
   'dessert', 500, 150, true, false, false, false),
  ('33333333-6000-0000-0000-000000000025', 'Salade de fruits',
   'Assortiment de fruits frais de saison',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000026', 'Île flottante',
   'Meringue pochée sur crème anglaise, caramel',
   'dessert', 1500, 550, true, false, false, false),
  ('33333333-6000-0000-0000-000000000027', 'Flan au caramel',
   'Flan aux œufs, nappé de caramel',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000028', 'Profiteroles',
   'Choux garnis de glace vanille, sauce chocolat chaud',
   'dessert', 1800, 650, true, true, false, false),
  ('33333333-6000-0000-0000-000000000029', 'Crêpes (sucre, miel, chocolat)',
   'Crêpes fines au choix : sucre, miel ou chocolat',
   'dessert', 800, 250, true, false, false, false),
  ('33333333-6000-0000-0000-000000000030', 'Churros',
   'Bâtonnets de pâte frite, sucre et cannelle, sauce chocolat',
   'dessert', 1000, 350, true, false, false, false),
  ('33333333-6000-0000-0000-000000000031', 'Gaufres',
   'Gaufres croustillantes, sucre glace ou garniture au choix',
   'dessert', 1000, 350, true, false, false, false)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.4h Photos des plats — URLs Wikimedia Commons, Unsplash & Pexels
-- --------------------------------------------------------------------------

-- ═══════════════════════════════════════════════════════════════════════════
-- Plats ivoiriens originaux (7.4)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Poulet_brais%C3%A9_attiek%C3%A9.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000001'; -- Attiéké Poulet Grillé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Poulet_DG.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000002'; -- Poulet DG
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000003'; -- Kedjenou de Poulet
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000004'; -- Foutou Sauce Graine
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Senegalese_Thieboudienne.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000005'; -- Riz Sauce Tomate Poisson
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Garba_plat_ivoirien.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000006'; -- Garba
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Un_plat_d%27alloco_Fried_Plantains.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000007'; -- Alloco Omelette
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000008'; -- Sauce Gombo + Riz
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_igname_accompagn%C3%A9_de_sauce_arachide.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000009'; -- Placali Sauce Arachide
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Jollof_rice_with_vegetable.jpg?width=600' WHERE id = '33333333-0000-0000-0000-000000000010'; -- Riz Djoumblé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Attieke_poisson_in_Abidjan_C%C3%B4te_d%27Ivoire.JPG?width=600' WHERE id = '33333333-0000-0000-0000-000000000011'; -- Tilapia Braisé
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop' WHERE id = '33333333-0000-0000-0000-000000000012'; -- Salade Composée
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kosai%28Akara%29.jpg?width=600' WHERE id = '33333333-0000-0000-0000-000000000013'; -- Beignets Haricots
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&h=400&fit=crop' WHERE id = '33333333-0000-0000-0000-000000000014'; -- Gâteau Ananas
UPDATE dishes SET photo_url = 'https://images.pexels.com/photos/8678927/pexels-photo-8678927.jpeg?auto=compress&cs=tinysrgb&w=600' WHERE id = '33333333-0000-0000-0000-000000000015'; -- Bissap Maison

-- ═══════════════════════════════════════════════════════════════════════════
-- Entrées (7.4b)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000001'; -- Salade César
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Flickr_-_cyclonebill_-_Salade_ni%C3%A7oise.jpg/600px-Flickr_-_cyclonebill_-_Salade_ni%C3%A7oise.jpg' WHERE id = '33333333-1000-0000-0000-000000000002'; -- Salade Niçoise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000003'; -- Salade de gésiers confits
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000004'; -- Salade de foie de volaille
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000005'; -- Salade du Chef
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1623428187969-5da2dcea5ebf?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000006'; -- Salade Grecque
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000007'; -- Farandole de crudités
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1607330289024-1535c6b4e1c1?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000008'; -- Salade de carottes Thaï
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1604909052743-94e838986d24?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000009'; -- Salade de poulet croustillant
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1633436375153-d7045cb93e38?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000010'; -- Œufs Mimosas
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1510693206972-df098062cb71?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000011'; -- Œufs en cocotte
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1511690743698-d9d18f7e20f1?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000012'; -- Salade de lentilles
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000013'; -- Salade d'avocat villageoise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000014'; -- Salade d'avocat crevettes mangues
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000015'; -- Salade de bœuf
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1607532941433-304659e8198a?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000016'; -- Salade Piémontaise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000017'; -- Salade de maïs
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Traditional_Tabbouleh.JPG/600px-Traditional_Tabbouleh.JPG' WHERE id = '33333333-1000-0000-0000-000000000018'; -- Taboulé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Poulet_brais%C3%A9_attiek%C3%A9.JPG?width=600' WHERE id = '33333333-1000-0000-0000-000000000019'; -- Salade d'attiéké
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kosai%28Akara%29.jpg?width=600' WHERE id = '33333333-1000-0000-0000-000000000020'; -- Beignets à la sardine
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Filled_tomatoes.JPG/600px-Filled_tomatoes.JPG' WHERE id = '33333333-1000-0000-0000-000000000021'; -- Tomates farcies
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1559564484-e48b3e040ff4?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000022'; -- Tarte tomate thon
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1608039829572-2b0f4a41af53?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000023'; -- Quiche au jambon
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Mushroom_and_leek_quiche.jpg/600px-Mushroom_and_leek_quiche.jpg' WHERE id = '33333333-1000-0000-0000-000000000024'; -- Tarte aux champignons
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1506280754576-f6fa8a873550?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000025'; -- Tarte à l'oignon
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1607532941433-304659e8198a?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000026'; -- Salade périgourdine
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1592417817098-8fd3d9eb14a5?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000027'; -- Salade de tomates pesto
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1541014741259-de529411b96a?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000028'; -- Salade asiatique concombres
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000029'; -- Salade avocat poulet grillé
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000030'; -- Salade haricots verts thon
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/Salade_lyonnaise.JPG/600px-Salade_lyonnaise.JPG' WHERE id = '33333333-1000-0000-0000-000000000031'; -- Salade Lyonnaise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1633436375153-d7045cb93e38?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000032'; -- Œufs de Moumar
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c6/%D0%9F%D0%BE%D0%BB%D0%BD%D0%B5%D1%82%D0%B8_%D1%82%D0%B8%D0%BA%D0%B2%D0%B8%D1%86%D0%B8.jpg/600px-%D0%9F%D0%BE%D0%BB%D0%BD%D0%B5%D1%82%D0%B8_%D1%82%D0%B8%D0%BA%D0%B2%D0%B8%D1%86%D0%B8.jpg' WHERE id = '33333333-1000-0000-0000-000000000033'; -- Courgettes farcies
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000034'; -- Salade de langue de bœuf
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Quiche_lorraine_02.JPG/600px-Quiche_lorraine_02.JPG' WHERE id = '33333333-1000-0000-0000-000000000035'; -- Quiche aux crevettes
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Quiche_lorraine_02.JPG/600px-Quiche_lorraine_02.JPG' WHERE id = '33333333-1000-0000-0000-000000000036'; -- Quiche aux écrevisses
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a8/Quiche_lorraine_01.JPG/600px-Quiche_lorraine_01.JPG' WHERE id = '33333333-1000-0000-0000-000000000037'; -- Quiche lorraine
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000038'; -- Avocats pamplemousse crevettes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000039'; -- Velouté de courges
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1541014741259-de529411b96a?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000040'; -- Salade concombres thaïlandaise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1519676867240-f03562e64571?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000041'; -- Aumônière de crêpes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1519676867240-f03562e64571?w=600&h=400&fit=crop' WHERE id = '33333333-1000-0000-0000-000000000042'; -- Crêpes roulées

-- ═══════════════════════════════════════════════════════════════════════════
-- Sauces traditionnelles (7.4c)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000001'; -- Sauce djoumgblé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000002'; -- Sauce gouagouassou
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000003'; -- Sauce gombo
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000004'; -- Sauce Kopê
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000005'; -- Sauce kwala
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000006'; -- Sauce graine
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000007'; -- Sauce claire
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000008'; -- Soumara Lafri
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou_de_Poisson.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000009'; -- Soupe du pêcheur
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Fufu_accompagn%C3%A9_d%27une_sauce_arachide_au_poulet.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000010'; -- Sauce Arachide
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Fufu_accompagn%C3%A9_d%27une_sauce_arachide_au_poulet.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000011'; -- Sauce Arachide-Dah
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000012'; -- Sauce pistache
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000013'; -- Biokesseu
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000014'; -- Sauce N'tro
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000015'; -- Sauce Akpi
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000016'; -- Akpessi
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou_de_Poisson.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000017'; -- Citrouille de crabes
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000018'; -- Sauce feuille
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000019'; -- Kédjénou
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou_de_Poisson.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000020'; -- Pépésoupe de carpes
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000021'; -- Pépésoupe de tripes
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000022'; -- Kédjénou de pintade
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000023'; -- Pépésoupe de pâtes
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_igname_accompagn%C3%A9_de_sauce_arachide.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000024'; -- Sauce Mafé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000025'; -- Soupou Kandia
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Poulet_Yassa.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000026'; -- Yassa de poulet
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Attieke_poisson_in_Abidjan_C%C3%B4te_d%27Ivoire.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000027'; -- Yassa de poisson
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000028'; -- Tchiou boulettes
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Attieke_poisson_in_Abidjan_C%C3%B4te_d%27Ivoire.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000029'; -- Sauce moyo
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Sauce_graine_de_palme.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000030'; -- Sauce tomate gingembre gombo
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Kedjenou_de_Poisson.JPG?width=600' WHERE id = '33333333-2000-0000-0000-000000000031'; -- Sauce dja

-- ═══════════════════════════════════════════════════════════════════════════
-- Plats africains (7.4d)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Choukouya_de_poulet.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000001'; -- Choukouya de poulet
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Du_poulet_braiser_ivoirien.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000002'; -- Poulet braisé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Du_poulet_braiser_ivoirien.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000003'; -- Poulet sauté
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Choukouya_de_poulet.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000004'; -- Brochettes de poulet
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000005'; -- Choukouya de porc
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000006'; -- Porc braisé
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000007'; -- Porc au four
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Attieke_poisson_in_Abidjan_C%C3%B4te_d%27Ivoire.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000008'; -- Poisson fumé braisé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Jollof_rice_with_vegetable.jpg?width=600' WHERE id = '33333333-3000-0000-0000-000000000009'; -- Djenkoumé
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Riz-Sauce_Graine.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000010'; -- Feijoada togolaise
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Choukouya_de_poulet.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000011'; -- Choukouya de bœuf
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1534939561126-855b8675edd7?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000012'; -- Jarret de bœuf braisé
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000013'; -- Brochettes de Kefta
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Poulet_brais%C3%A9_attiek%C3%A9.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000014'; -- APF
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Senegalese_Thieboudienne.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000015'; -- Tchep au poulet
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Senegalese_Thieboudienne.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000016'; -- Tchep viande olives
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Thieboudienne.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000017'; -- Tchep blanc poisson
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Red_Thieboudienne.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000018'; -- Tchep rouge poisson
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=600&h=400&fit=crop' WHERE id = '33333333-3000-0000-0000-000000000019'; -- Vermicelles sénégalaises
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Couscous_Royal_Marocain.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000020'; -- Couscous sénégalais
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Moroccan_TAGINE.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000021'; -- Tajine de poulet
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Couscous_Royal_Marocain.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000022'; -- Couscous Royal
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Couscous_Royal_Marocain.JPG?width=600' WHERE id = '33333333-3000-0000-0000-000000000023'; -- Couscous Marocain

-- ═══════════════════════════════════════════════════════════════════════════
-- Plats du monde (7.4e)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000001'; -- Colombo de porc
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000002'; -- Rôti de porc
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000003'; -- Mijoté de boulettes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000004'; -- Bœuf sauté champignons noirs
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/a/a0/Chicken_fricassee-01-2.JPG' WHERE id = '33333333-4000-0000-0000-000000000005'; -- Fricassée de poulet
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000006'; -- Poulet aux champignons
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/4/46/Coq_au_riesling.JPG' WHERE id = '33333333-4000-0000-0000-000000000007'; -- Poulet chasseur
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/7/76/Shepherds_pie.JPG' WHERE id = '33333333-4000-0000-0000-000000000008'; -- Hachis parmentier
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/5/51/Coq_au_Vin_6of7_%288735164745%29.jpg' WHERE id = '33333333-4000-0000-0000-000000000009'; -- Coq au vin
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1580476262798-bddd9f4b7369?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000010'; -- Petit pois boulettes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000011'; -- Haricots rouges bœuf
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1580476262798-bddd9f4b7369?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000012'; -- Steak de thon
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000013'; -- Rognons au Calvados
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000014'; -- Poulet rôti
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000015'; -- Bœuf stroganoff
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1558030006-450675393462?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000016'; -- Gigot rôti
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000017'; -- Poulet farci champignons
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000018'; -- Gratin de pâtes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1529042410759-befb1204b468?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000019'; -- Boulettes poulet teriyaki
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1604497181015-76590d828b75?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000020'; -- Poulet pané
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000021'; -- Riz crevettes bœuf
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1534080564583-6be75777b70a?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000022'; -- Paella sénégalaise
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000023'; -- Escalope poulet farcie
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1580476262798-bddd9f4b7369?w=600&h=400&fit=crop' WHERE id = '33333333-4000-0000-0000-000000000024'; -- Poisson papillote
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/0/09/Souris_d%27agneau.JPG' WHERE id = '33333333-4000-0000-0000-000000000025'; -- Souris d'agneau
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-4000-0000-0000-000000000026'; -- Ragoût d'ignames

-- ═══════════════════════════════════════════════════════════════════════════
-- Accompagnements (7.4f)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44c28?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000001'; -- Riz blanc
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_igname_accompagn%C3%A9_de_sauce_arachide.JPG?width=600' WHERE id = '33333333-5000-0000-0000-000000000002'; -- Foutou
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/Cuisine_de_C%C3%B4te_d%27Ivoire_-_Du_placali.JPG/600px-Cuisine_de_C%C3%B4te_d%27Ivoire_-_Du_placali.JPG' WHERE id = '33333333-5000-0000-0000-000000000003'; -- Placali
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-5000-0000-0000-000000000004'; -- Toh
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1630384060421-cb20d0e0649d?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000005'; -- Frites
UPDATE dishes SET photo_url = 'https://images.pexels.com/photos/1583884/pexels-photo-1583884.jpeg?auto=compress&cs=tinysrgb&w=600' WHERE id = '33333333-5000-0000-0000-000000000006'; -- Pommes de terre sautées
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000007'; -- Galettes pommes de terre
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000008'; -- Croquettes pomme de terre
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-5000-0000-0000-000000000009'; -- Croquettes d'ignames
UPDATE dishes SET photo_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Foutou_%C3%A0_la_sauce_graine.JPG?width=600' WHERE id = '33333333-5000-0000-0000-000000000010'; -- Ignames Araignée
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Attieke.JPG/600px-Attieke.JPG' WHERE id = '33333333-5000-0000-0000-000000000011'; -- Attiéké
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e1/Alloko_%28frite_de_banane_platain%29_pr%C3%A8s.JPG/600px-Alloko_%28frite_de_banane_platain%29_pr%C3%A8s.JPG' WHERE id = '33333333-5000-0000-0000-000000000012'; -- Aloco
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Claclo.JPG/600px-Claclo.JPG' WHERE id = '33333333-5000-0000-0000-000000000013'; -- Claclo
UPDATE dishes SET photo_url = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=600' WHERE id = '33333333-5000-0000-0000-000000000014'; -- Jardinière de légumes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1580013759032-93f90a57750d?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000015'; -- Épinards sautés
UPDATE dishes SET photo_url = 'https://images.pexels.com/photos/1373915/pexels-photo-1373915.jpeg?auto=compress&cs=tinysrgb&w=600' WHERE id = '33333333-5000-0000-0000-000000000016'; -- Spaghettis
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44c28?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000017'; -- Riz au curry
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000018'; -- Riz cantonais
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44c28?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000019'; -- Riz Pilaf
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600&h=400&fit=crop' WHERE id = '33333333-5000-0000-0000-000000000020'; -- Gratin dauphinois

-- ═══════════════════════════════════════════════════════════════════════════
-- Desserts (7.4g)
-- ═══════════════════════════════════════════════════════════════════════════
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000001'; -- Tarte au citron
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1562007908-17c67e878c88?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000002'; -- Gâteau aux pommes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000003'; -- Tarte à l'orange
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1562007908-17c67e878c88?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000004'; -- Moelleux à l'orange
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000005'; -- Beignets aux pommes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1604495772376-9657f0035eb5?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000006'; -- Beignets à la banane
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000007'; -- Cake au citron
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000008'; -- Cake au chocolat
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000009'; -- Cake Marbré
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000010'; -- Cake au yaourt
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1568571780765-9276ac8b75a2?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000011'; -- Cake à la banane
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000012'; -- Tarte tatin mangue
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000013'; -- Gâteau à l'ananas
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/K%C3%A4%C3%A4retorttu.jpg/600px-K%C3%A4%C3%A4retorttu.jpg' WHERE id = '33333333-6000-0000-0000-000000000014'; -- Gâteau roulé confiture
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/07/Madeleines_de_Commercy.jpg/600px-Madeleines_de_Commercy.jpg' WHERE id = '33333333-6000-0000-0000-000000000015'; -- Madeleines
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/46/Nigerian-puff-puff-recipe_cropped.jpg/600px-Nigerian-puff-puff-recipe_cropped.jpg' WHERE id = '33333333-6000-0000-0000-000000000016'; -- Thiopati
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000017'; -- Beignets de carnaval
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Golden_Mikate%CC%81.jpg/600px-Golden_Mikate%CC%81.jpg' WHERE id = '33333333-6000-0000-0000-000000000018'; -- Gbofotos
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000019'; -- Yaourt façon Mily's
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c3/Degue_from_Burkina_Faso.jpg/600px-Degue_from_Burkina_Faso.jpg' WHERE id = '33333333-6000-0000-0000-000000000020'; -- Thiakry
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1607920591413-4ec007e70023?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000021'; -- Brownies M&Ms
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1541783245831-57d6fb0926d3?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000022'; -- Mousse au chocolat
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/d/d7/Eclair%28dessert%29.JPG' WHERE id = '33333333-6000-0000-0000-000000000023'; -- Éclair au chocolat
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/3/32/Chouquettes.jpg/600px-Chouquettes.jpg' WHERE id = '33333333-6000-0000-0000-000000000024'; -- Chouquettes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000025'; -- Salade de fruits
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Ujuvad_saarekesed.jpg/600px-Ujuvad_saarekesed.jpg' WHERE id = '33333333-6000-0000-0000-000000000026'; -- Île flottante
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/87/Creme_Caramel_India.JPG/600px-Creme_Caramel_India.JPG' WHERE id = '33333333-6000-0000-0000-000000000027'; -- Flan au caramel
UPDATE dishes SET photo_url = 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/Profiteroles_by_Star5112.jpg/600px-Profiteroles_by_Star5112.jpg' WHERE id = '33333333-6000-0000-0000-000000000028'; -- Profiteroles
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1635362825546-eb763064db11?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000029'; -- Crêpes
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1624371414361-e670246e5ba3?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000030'; -- Churros
UPDATE dishes SET photo_url = 'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=600&h=400&fit=crop' WHERE id = '33333333-6000-0000-0000-000000000031'; -- Gaufres


-- --------------------------------------------------------------------------
-- 7.5 Ingrédients
-- --------------------------------------------------------------------------
INSERT INTO ingredients (id, name, unit, current_stock, min_stock, cost_per_unit, category)
VALUES
  ('44444444-0000-0000-0000-000000000001', 'Attiéké (semoule manioc)', 'kg',   50.0, 15.0,  800, 'féculent'),
  ('44444444-0000-0000-0000-000000000002', 'Poulet entier',            'kg',   40.0, 10.0, 2500, 'viande'),
  ('44444444-0000-0000-0000-000000000003', 'Banane plantain',          'kg',   30.0,  8.0,  400, 'légume'),
  ('44444444-0000-0000-0000-000000000004', 'Riz importé',              'kg',   80.0, 25.0,  600, 'féculent'),
  ('44444444-0000-0000-0000-000000000005', 'Huile de palme',           'L',     8.0,  5.0,  900, 'matière_grasse'),
  ('44444444-0000-0000-0000-000000000006', 'Tomates fraîches',         'kg',   12.0,  4.0,  500, 'légume'),
  ('44444444-0000-0000-0000-000000000007', 'Oignons',                  'kg',   15.0,  5.0,  300, 'légume'),
  ('44444444-0000-0000-0000-000000000008', 'Piment rouge',             'kg',    2.0,  1.0,  700, 'épice'),
  ('44444444-0000-0000-0000-000000000009', 'Graine de palme',          'kg',   10.0,  3.0, 1200, 'condiment'),
  ('44444444-0000-0000-0000-000000000010', 'Thon en conserve',         'boite', 60.0, 20.0,  900, 'poisson'),
  ('44444444-0000-0000-0000-000000000011', 'Tilapia frais',            'kg',   15.0,  5.0, 2000, 'poisson'),
  ('44444444-0000-0000-0000-000000000012', 'Gombo frais',              'kg',    5.0,  2.0,  600, 'légume'),
  ('44444444-0000-0000-0000-000000000013', 'Igname',                   'kg',   20.0,  8.0,  400, 'féculent'),
  ('44444444-0000-0000-0000-000000000014', 'Haricots noirs',           'kg',   10.0,  3.0,  500, 'légumineuse'),
  ('44444444-0000-0000-0000-000000000015', 'Sel de mer',               'kg',    3.0,  1.0,  200, 'épice')
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.6 Fournisseurs
-- --------------------------------------------------------------------------
INSERT INTO suppliers (id, name, contact_name, phone, city, is_active)
VALUES
  ('55555555-0000-0000-0000-000000000001',
   'Marché Adjamé Frais', 'Mamadou Konaté', '+225 07 77 00 01 01', 'Abidjan', true),
  ('55555555-0000-0000-0000-000000000002',
   'Grossiste Koumassi', 'Fatou Traoré', '+225 07 77 00 02 02', 'Abidjan', true),
  ('55555555-0000-0000-0000-000000000003',
   'Ferme Yamoussoukro', 'Koffi N''Guessan', '+225 07 77 00 03 03', 'Yamoussoukro', true)
ON CONFLICT DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.7 Formules
-- --------------------------------------------------------------------------
INSERT INTO formulas (id, name, base_price, description, is_active)
VALUES
  ('77777777-0000-0000-0000-000000000001', 'Standard',   3000, 'Plat principal au choix',                true),
  ('77777777-0000-0000-0000-000000000002', 'Premium',    4500, 'Entrée + plat principal + dessert',      true),
  ('77777777-0000-0000-0000-000000000003', 'Végétarien', 2500, 'Plat végétarien du jour',                true),
  ('77777777-0000-0000-0000-000000000004', 'Économique', 2000, 'Plat unique du jour (pas de choix)',     true)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.8 Menu hebdomadaire (semaine du 23–27 Fév 2026)
-- --------------------------------------------------------------------------
INSERT INTO menus (id, name, week_start, week_end, is_published)
VALUES
  ('66666666-0000-0000-0000-000000000001',
   'Menu semaine du 23 au 27 Février 2026',
   '2026-02-23', '2026-02-27', true)
ON CONFLICT (week_start) DO NOTHING;

-- Items du menu hebdomadaire — 1=Lun, 2=Mar, 3=Mer, 4=Jeu, 5=Ven
-- Chaque jour : 1 entrée (is_starter=true) + 2 plats principaux au choix
INSERT INTO menu_items (menu_id, dish_id, day_of_week, is_starter, sort_order, max_quantity)
VALUES
  -- Lundi 23/02
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000012', 1, true,  1, 100),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000004', 1, false, 2, 150),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000005', 1, false, 3, 150),
  -- Mardi 24/02
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000013', 2, true,  1,  80),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000001', 2, false, 2, 200),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000008', 2, false, 3, 120),
  -- Mercredi 25/02
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000012', 3, true,  1, 100),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000002', 3, false, 2, 150),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000009', 3, false, 3, 100),
  -- Jeudi 26/02
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000013', 4, true,  1,  80),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000006', 4, false, 2, 200),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000010', 4, false, 3, 120),
  -- Vendredi 27/02
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000012', 5, true,  1, 100),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000002', 5, false, 2, 150),
  ('66666666-0000-0000-0000-000000000001', '33333333-0000-0000-0000-000000000011', 5, false, 3, 120)
ON CONFLICT (menu_id, dish_id, day_of_week) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.8b Menu semaine+1 (2–6 Mars 2026)
-- --------------------------------------------------------------------------
INSERT INTO menus (id, name, week_start, week_end, is_published, selection_deadline)
VALUES
  ('66666666-0000-0000-0000-000000000002',
   'Menu semaine du 2 au 6 Mars 2026',
   '2026-03-02', '2026-03-06', true,
   '2026-02-27 18:00:00+00')
ON CONFLICT (week_start) DO NOTHING;

INSERT INTO menu_items (menu_id, dish_id, day_of_week, is_starter, sort_order, max_quantity)
VALUES
  -- Lundi 02/03
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000013', 1, true,  1, 100),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', 1, false, 2, 200),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000006', 1, false, 3, 150),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000009', 1, false, 4, 120),
  -- Mardi 03/03
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000012', 2, true,  1,  80),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000002', 2, false, 2, 150),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000004', 2, false, 3, 150),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000010', 2, false, 4, 100),
  -- Mercredi 04/03
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000013', 3, true,  1, 100),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000005', 3, false, 2, 180),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000008', 3, false, 3, 120),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000011', 3, false, 4, 100),
  -- Jeudi 05/03
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000012', 4, true,  1,  80),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000001', 4, false, 2, 200),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000009', 4, false, 3, 150),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000004', 4, false, 4, 120),
  -- Vendredi 06/03
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000013', 5, true,  1, 100),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000006', 5, false, 2, 200),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000002', 5, false, 3, 150),
  ('66666666-0000-0000-0000-000000000002', '33333333-0000-0000-0000-000000000005', 5, false, 4, 120)
ON CONFLICT (menu_id, dish_id, day_of_week) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.8c Orders history for employe1@orange.ci (2 months)
-- --------------------------------------------------------------------------
INSERT INTO orders (id, user_id, dish_id, site_id, order_date, status, total_price, extras, special_instructions)
VALUES
  -- Février 2026 (semaine courante et passées)
  ('77777777-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-02-23', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', '22222222-0000-0000-0000-000000000001', '2026-02-24', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', '2026-02-25', 'served', 5500, '[{"dish_id":"33333333-6000-0000-0000-000000000001","quantity":1,"unit_price":500}]', NULL),
  ('77777777-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000006', '22222222-0000-0000-0000-000000000001', '2026-02-26', 'confirmed', 5300, '[{"dish_id":"33333333-7000-0000-0000-000000000001","quantity":1,"unit_price":300}]', NULL),
  ('77777777-0000-0000-0000-000000000005', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000010', '22222222-0000-0000-0000-000000000001', '2026-02-27', 'confirmed', 5000, '[]', NULL),
  -- Février (semaine du 16-20)
  ('77777777-0000-0000-0000-000000000006', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000005', '22222222-0000-0000-0000-000000000001', '2026-02-16', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000007', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000008', '22222222-0000-0000-0000-000000000001', '2026-02-17', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000008', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-02-18', 'served', 5500, '[{"dish_id":"33333333-6000-0000-0000-000000000002","quantity":1,"unit_price":500}]', NULL),
  ('77777777-0000-0000-0000-000000000009', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000009', '22222222-0000-0000-0000-000000000001', '2026-02-19', 'cancelled', 5000, '[]', 'Absent pour raison personnelle'),
  ('77777777-0000-0000-0000-000000000010', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', '2026-02-20', 'served', 5000, '[]', NULL),
  -- Février (semaine du 9-13)
  ('77777777-0000-0000-0000-000000000011', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', '22222222-0000-0000-0000-000000000001', '2026-02-09', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000012', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000006', '22222222-0000-0000-0000-000000000001', '2026-02-10', 'served', 5800, '[{"dish_id":"33333333-6000-0000-0000-000000000001","quantity":1,"unit_price":500},{"dish_id":"33333333-7000-0000-0000-000000000001","quantity":1,"unit_price":300}]', NULL),
  ('77777777-0000-0000-0000-000000000013', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000011', '22222222-0000-0000-0000-000000000001', '2026-02-11', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000014', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-02-12', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000015', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000005', '22222222-0000-0000-0000-000000000001', '2026-02-13', 'served', 5000, '[]', NULL),
  -- Février (semaine du 2-6)
  ('77777777-0000-0000-0000-000000000016', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', '2026-02-02', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000017', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000008', '22222222-0000-0000-0000-000000000001', '2026-02-03', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000018', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000010', '22222222-0000-0000-0000-000000000001', '2026-02-04', 'served', 5500, '[{"dish_id":"33333333-6000-0000-0000-000000000001","quantity":1,"unit_price":500}]', NULL),
  ('77777777-0000-0000-0000-000000000019', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', '22222222-0000-0000-0000-000000000001', '2026-02-05', 'no_show', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000020', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-02-06', 'served', 5000, '[]', NULL),
  -- Janvier 2026 (10 commandes)
  ('77777777-0000-0000-0000-000000000021', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000006', '22222222-0000-0000-0000-000000000001', '2026-01-05', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000022', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-01-06', 'served', 5500, '[{"dish_id":"33333333-6000-0000-0000-000000000002","quantity":1,"unit_price":500}]', NULL),
  ('77777777-0000-0000-0000-000000000023', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000009', '22222222-0000-0000-0000-000000000001', '2026-01-07', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000024', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000005', '22222222-0000-0000-0000-000000000001', '2026-01-08', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000025', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000001', '2026-01-09', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000026', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000011', '22222222-0000-0000-0000-000000000001', '2026-01-12', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000027', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000004', '22222222-0000-0000-0000-000000000001', '2026-01-13', 'served', 5800, '[{"dish_id":"33333333-6000-0000-0000-000000000001","quantity":1,"unit_price":500},{"dish_id":"33333333-7000-0000-0000-000000000001","quantity":1,"unit_price":300}]', NULL),
  ('77777777-0000-0000-0000-000000000028', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000008', '22222222-0000-0000-0000-000000000001', '2026-01-14', 'served', 5000, '[]', NULL),
  ('77777777-0000-0000-0000-000000000029', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', '2026-01-15', 'cancelled', 5000, '[]', 'Réunion externe'),
  ('77777777-0000-0000-0000-000000000030', 'aaaaaaaa-0000-0000-0000-000000000005', '33333333-0000-0000-0000-000000000010', '22222222-0000-0000-0000-000000000001', '2026-01-16', 'served', 5000, '[]', NULL)
ON CONFLICT (user_id, order_date) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.8d Weekly plans for employe1@orange.ci (current week)
-- --------------------------------------------------------------------------
INSERT INTO weekly_plans (id, user_id, menu_id, status, confirmed_at)
VALUES
  ('88888888-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000005',
   '66666666-0000-0000-0000-000000000001', 'confirmed', '2026-02-19 14:30:00+00')
ON CONFLICT (user_id, menu_id) DO NOTHING;

INSERT INTO weekly_plan_items (weekly_plan_id, day_of_week, dish_id, is_locked, locked_at, extras)
VALUES
  ('88888888-0000-0000-0000-000000000001', 1, '33333333-0000-0000-0000-000000000004', true, '2026-02-20 00:00:00+00', '[]'),
  ('88888888-0000-0000-0000-000000000001', 2, '33333333-0000-0000-0000-000000000001', true, '2026-02-21 00:00:00+00', '[]'),
  ('88888888-0000-0000-0000-000000000001', 3, '33333333-0000-0000-0000-000000000002', true, '2026-02-22 00:00:00+00', '[{"dish_id":"33333333-6000-0000-0000-000000000001","quantity":1,"unit_price":500}]'),
  ('88888888-0000-0000-0000-000000000001', 4, '33333333-0000-0000-0000-000000000006', true, '2026-02-23 00:00:00+00', '[{"dish_id":"33333333-7000-0000-0000-000000000001","quantity":1,"unit_price":300}]'),
  ('88888888-0000-0000-0000-000000000001', 5, '33333333-0000-0000-0000-000000000002', true, '2026-02-24 00:00:00+00', '[]')
ON CONFLICT (weekly_plan_id, day_of_week) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.8e Update contracts: Orange=invoice, TotalEnergies=tickets, SGBCI=invoice
-- --------------------------------------------------------------------------
UPDATE company_contracts
SET working_days = 5, payment_mode = 'invoice', advance_weeks = 2
WHERE company_id = '11111111-0000-0000-0000-000000000001';

UPDATE company_contracts
SET working_days = 5, payment_mode = 'tickets', tickets_per_month = 24, advance_weeks = 2
WHERE company_id = '11111111-0000-0000-0000-000000000002';

UPDATE company_contracts
SET working_days = 5, payment_mode = 'invoice', advance_weeks = 2
WHERE company_id = '11111111-0000-0000-0000-000000000003';

-- Update ticket_balance for TotalEnergies employees
UPDATE profiles SET ticket_balance = 18
WHERE company_id = '11111111-0000-0000-0000-000000000002' AND is_active = true;

-- Update selection_deadline for current week menu
UPDATE menus SET selection_deadline = '2026-02-20 18:00:00+00'
WHERE id = '66666666-0000-0000-0000-000000000001';

-- --------------------------------------------------------------------------
-- 7.9 Configuration applicative
-- --------------------------------------------------------------------------
INSERT INTO app_config (key, value, description) VALUES
  ('app_name',             '"MILY''S Gourmet"',                                    'Nom de l''application'),
  ('app_timezone',         '"Africa/Abidjan"',                                     'Fuseau horaire'),
  ('app_currency',         '"XOF"',                                                'Devise (FCFA)'),
  ('app_country',          '"CI"',                                                 'Code pays ISO'),
  ('order_cutoff_midi',    '"10:30"',                                              'Heure limite commande déjeuner'),
  ('delivery_target_midi', '"12:30"',                                              'Heure cible livraison déjeuner'),
  ('tva_rate',             '18',                                                   'Taux TVA Côte d''Ivoire (%)'),
  ('invoice_payment_days', '30',                                                   'Délai de paiement factures (jours)'),
  ('max_advance_days',     '5',                                                    'Commandes max à l''avance (jours)'),
  ('plan_deadline_day',    '4',                                                    'Jour limite planning semaine (4=jeudi)'),
  ('plan_deadline_hour',   '"18:00"',                                              'Heure limite planning semaine'),
  ('support_phone',        '"+225 07 00 00 00 00"',                               'Numéro support client'),
  ('support_email',        '"support@milys-gourmet.ci"',                          'Email support client'),
  ('milys_address',        '"Cocody Riviera Palmeraie, Abidjan, Côte d''Ivoire"', 'Adresse MILY''S')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- --------------------------------------------------------------------------
-- 7.10 Profils employés (20 employés répartis dans les 3 entreprises)
-- --------------------------------------------------------------------------
-- NOTE : Les UUID ci-dessous sont les id issus de auth.users.
-- En développement, créer d'abord les utilisateurs Supabase Auth puis
-- insérer les profils. Les INSERT ON CONFLICT permettent le rejeu.
-- --------------------------------------------------------------------------

-- IDs fixes pour les utilisateurs de test
-- admin@milys.ci        → aaaaaaaa-0000-0000-0000-000000000001
-- kitchen@milys.ci      → aaaaaaaa-0000-0000-0000-000000000002
-- cashier@milys.ci      → aaaaaaaa-0000-0000-0000-000000000003
-- rh@arti.ci            → aaaaaaaa-0000-0000-0000-000000000004
-- employee1@arti.ci     → aaaaaaaa-0000-0000-0000-000000000005
-- Employés supplémentaires → aaaaaaaa-0000-0000-0000-0000000000XX

INSERT INTO profiles (id, email, full_name, phone, employee_type, matricule, company_id, site_id, department, is_active)
VALUES
  -- Staff MILY'S (pas de company_id)
  ('aaaaaaaa-0000-0000-0000-000000000001', 'admin@milys.ci',       'Kouadio Yao Marcel',    '+225 07 01 00 00 01', 'regular', 'MLY-001', NULL, NULL, 'Direction', true),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'kitchen@milys.ci',     'Bamba Aminata',         '+225 07 01 00 00 02', 'regular', 'MLY-002', NULL, NULL, 'Cuisine', true),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'cashier@milys.ci',     'Touré Ibrahim',         '+225 07 01 00 00 03', 'regular', 'MLY-003', NULL, NULL, 'Caisse', true),

  -- Orange CI (company 1) — 7 employés
  ('aaaaaaaa-0000-0000-0000-000000000004', 'rh@orange.ci',         'Diallo Fatoumata',      '+225 07 02 00 00 01', 'regular', 'OCI-001', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'Ressources Humaines', true),
  ('aaaaaaaa-0000-0000-0000-000000000005', 'employe1@orange.ci',   'Koné Moussa',           '+225 07 02 00 00 02', 'regular', 'OCI-002', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'Informatique', true),
  ('aaaaaaaa-0000-0000-0000-000000000006', 'employe2@orange.ci',   'Sangaré Awa',           '+225 07 02 00 00 03', 'regular', 'OCI-003', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'Marketing', true),
  ('aaaaaaaa-0000-0000-0000-000000000007', 'employe3@orange.ci',   'Coulibaly Jean-Marc',   '+225 07 02 00 00 04', 'regular', 'OCI-004', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000002', 'Commercial', true),
  ('aaaaaaaa-0000-0000-0000-000000000008', 'employe4@orange.ci',   'N''Guessan Élodie',     '+225 07 02 00 00 05', 'regular', 'OCI-005', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000002', 'Finance', true),
  ('aaaaaaaa-0000-0000-0000-000000000009', 'employe5@orange.ci',   'Yao Serge',             '+225 07 02 00 00 06', 'intern',  'OCI-006', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000001', 'Informatique', true),
  ('aaaaaaaa-0000-0000-0000-000000000010', 'employe6@orange.ci',   'Traoré Mariam',         '+225 07 02 00 00 07', 'regular', 'OCI-007', '11111111-0000-0000-0000-000000000001', '22222222-0000-0000-0000-000000000002', 'Juridique', true),

  -- TotalEnergies CI (company 2) — 6 employés
  ('aaaaaaaa-0000-0000-0000-000000000011', 'rh@totalenergies.ci',  'Kouassi Brigitte',      '+225 07 03 00 00 01', 'regular', 'TTE-001', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000003', 'Ressources Humaines', true),
  ('aaaaaaaa-0000-0000-0000-000000000012', 'employe1@total.ci',    'Brou Stéphane',         '+225 07 03 00 00 02', 'regular', 'TTE-002', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000003', 'Ingénierie', true),
  ('aaaaaaaa-0000-0000-0000-000000000013', 'employe2@total.ci',    'Aka Rosalie',           '+225 07 03 00 00 03', 'regular', 'TTE-003', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000003', 'HSE', true),
  ('aaaaaaaa-0000-0000-0000-000000000014', 'employe3@total.ci',    'Ouattara Karim',        '+225 07 03 00 00 04', 'regular', 'TTE-004', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000004', 'Logistique', true),
  ('aaaaaaaa-0000-0000-0000-000000000015', 'employe4@total.ci',    'Gnamba Patricia',       '+225 07 03 00 00 05', 'regular', 'TTE-005', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000004', 'Finance', true),
  ('aaaaaaaa-0000-0000-0000-000000000016', 'employe5@total.ci',    'Konan Amédée',          '+225 07 03 00 00 06', 'guard',   'TTE-006', '11111111-0000-0000-0000-000000000002', '22222222-0000-0000-0000-000000000003', 'Sécurité', true),

  -- SGBCI (company 3) — 7 employés
  ('aaaaaaaa-0000-0000-0000-000000000017', 'rh@sgbci.ci',          'Ahui Marie-Claire',     '+225 07 04 00 00 01', 'regular', 'SGB-001', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000005', 'Ressources Humaines', true),
  ('aaaaaaaa-0000-0000-0000-000000000018', 'employe1@sgbci.ci',    'Gnamien Franck',        '+225 07 04 00 00 02', 'regular', 'SGB-002', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000005', 'Crédit', true),
  ('aaaaaaaa-0000-0000-0000-000000000019', 'employe2@sgbci.ci',    'Dembélé Habiba',        '+225 07 04 00 00 03', 'regular', 'SGB-003', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000005', 'Opérations', true),
  ('aaaaaaaa-0000-0000-0000-000000000020', 'employe3@sgbci.ci',    'Koffi Alain',           '+225 07 04 00 00 04', 'regular', 'SGB-004', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000006', 'Informatique', true),
  ('aaaaaaaa-0000-0000-0000-000000000021', 'employe4@sgbci.ci',    'Assamoi Nadège',        '+225 07 04 00 00 05', 'regular', 'SGB-005', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000006', 'Conformité', true),
  ('aaaaaaaa-0000-0000-0000-000000000022', 'employe5@sgbci.ci',    'Bakayoko Drissa',       '+225 07 04 00 00 06', 'regular', 'SGB-006', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000005', 'Finance', true),
  ('aaaaaaaa-0000-0000-0000-000000000023', 'employe6@sgbci.ci',    'Tanoh Véronique',       '+225 07 04 00 00 07', 'intern',  'SGB-007', '11111111-0000-0000-0000-000000000003', '22222222-0000-0000-0000-000000000006', 'Marketing', true)
ON CONFLICT (id) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.11 Rôles utilisateurs de test
-- --------------------------------------------------------------------------
INSERT INTO user_roles (user_id, role, company_id)
VALUES
  -- Staff MILY'S
  ('aaaaaaaa-0000-0000-0000-000000000001', 'superadmin',     NULL),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'milys_kitchen',  NULL),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'milys_cashier',  NULL),

  -- Company admins (RH)
  ('aaaaaaaa-0000-0000-0000-000000000004', 'company_admin',  '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000011', 'company_admin',  '11111111-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000017', 'company_admin',  '11111111-0000-0000-0000-000000000003'),

  -- Employés Orange CI
  ('aaaaaaaa-0000-0000-0000-000000000005', 'employee', '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000006', 'employee', '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000007', 'employee', '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000008', 'employee', '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000009', 'employee', '11111111-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000010', 'employee', '11111111-0000-0000-0000-000000000001'),

  -- Employés TotalEnergies CI
  ('aaaaaaaa-0000-0000-0000-000000000012', 'employee', '11111111-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000013', 'employee', '11111111-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000014', 'employee', '11111111-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000015', 'employee', '11111111-0000-0000-0000-000000000002'),
  ('aaaaaaaa-0000-0000-0000-000000000016', 'employee', '11111111-0000-0000-0000-000000000002'),

  -- Employés SGBCI
  ('aaaaaaaa-0000-0000-0000-000000000018', 'employee', '11111111-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000019', 'employee', '11111111-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000020', 'employee', '11111111-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000021', 'employee', '11111111-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000022', 'employee', '11111111-0000-0000-0000-000000000003'),
  ('aaaaaaaa-0000-0000-0000-000000000023', 'employee', '11111111-0000-0000-0000-000000000003')
ON CONFLICT (user_id, role) DO NOTHING;

-- --------------------------------------------------------------------------
-- 7.12 Utilisateurs Supabase Auth (test uniquement)
-- --------------------------------------------------------------------------
-- Ces utilisateurs sont créés via auth.users pour le développement local.
-- En production, les utilisateurs sont créés via le flow d'inscription.
-- Mots de passe : MilysAdmin2026! (pour tous les comptes de test)
--
-- Comptes de test principaux :
--   admin@milys.ci        → superadmin       (MilysAdmin2026!)
--   kitchen@milys.ci      → milys_kitchen    (MilysAdmin2026!)
--   cashier@milys.ci      → milys_cashier    (MilysAdmin2026!)
--   rh@orange.ci          → company_admin    (MilysAdmin2026!)
--   employe1@orange.ci    → employee         (MilysAdmin2026!)
--
-- NOTE : Supabase Auth gère auth.users séparément. Utilisez le dashboard
-- Supabase ou la CLI pour créer ces utilisateurs avec les UUID ci-dessus.

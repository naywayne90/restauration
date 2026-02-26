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
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name         TEXT NOT NULL,
    week_start   DATE NOT NULL,
    week_end     DATE NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT false,
    published_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes        TEXT,
    created_by   UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(week_start)
);

CREATE TABLE IF NOT EXISTS menu_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id      UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    dish_id      UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    day_of_week  INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 5),  -- 1=Lun…5=Ven
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
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    menu_id    UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    status     TEXT NOT NULL DEFAULT 'draft'
                   CHECK (status IN ('draft','confirmed','locked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, menu_id)
);

CREATE TABLE IF NOT EXISTS weekly_plan_items (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    day_of_week    INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 5),
    dish_id        UUID NOT NULL REFERENCES dishes(id) ON DELETE RESTRICT,
    is_cancelled   BOOLEAN NOT NULL DEFAULT false,
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

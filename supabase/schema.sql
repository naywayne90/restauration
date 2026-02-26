-- ============================================================================
-- MILY'S - Catering/Restauration Management App
-- Complete PostgreSQL Schema for Supabase
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 2. ENUM TYPES
-- ============================================================================
DO $$ BEGIN
    CREATE TYPE user_role_type AS ENUM (
        'superadmin', 'milys_admin', 'milys_kitchen', 'milys_logistics',
        'milys_cashier', 'company_admin', 'company_cashier',
        'third_party_cashier', 'employee'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE order_status_type AS ENUM (
        'pending', 'confirmed', 'in_production', 'ready',
        'delivering', 'delivered', 'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE delivery_status_type AS ENUM (
        'pending', 'in_transit', 'delivered', 'failed'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_status_type AS ENUM (
        'pending', 'partial', 'paid', 'overdue', 'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE payment_method_type AS ENUM (
        'cash', 'mobile_money', 'bank_transfer', 'card', 'ticket'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE ticket_status_type AS ENUM (
        'active', 'used', 'expired', 'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE stock_movement_type AS ENUM (
        'entry', 'exit', 'adjustment', 'waste'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE contract_type AS ENUM (
        'forfait', 'a_la_carte', 'mixed'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE meal_type AS ENUM (
        'petit_dejeuner', 'dejeuner', 'diner', 'collation'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 3. TABLES
-- ============================================================================

-- --------------------------------------------------------------------------
-- 3.1 Companies & Sites
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    address TEXT,
    city TEXT,
    contact_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS company_sites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    city TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS company_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    contract_type contract_type NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    daily_budget_per_employee NUMERIC(10,2),
    meal_types_included TEXT[],
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.2 Profiles & Roles
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE,
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    site_id UUID REFERENCES company_sites(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role user_role_type NOT NULL,
    granted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, role)
);

-- --------------------------------------------------------------------------
-- 3.3 Dishes, Ingredients & Recipes
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    image_url TEXT,
    base_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    is_available BOOLEAN NOT NULL DEFAULT true,
    preparation_time_min INTEGER,
    calories INTEGER,
    is_vegetarian BOOLEAN NOT NULL DEFAULT false,
    is_vegan BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    unit TEXT,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    stock_quantity NUMERIC(10,2) NOT NULL DEFAULT 0,
    min_stock_threshold NUMERIC(10,2) NOT NULL DEFAULT 0,
    category TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity_needed NUMERIC(10,3) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_allergens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    allergen_name TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dish_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.4 Suppliers & Stock
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    contact_name TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    city TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS supplier_ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    supply_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    delivery_delay_days INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    movement_type stock_movement_type NOT NULL,
    quantity NUMERIC(10,3) NOT NULL,
    reason TEXT,
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'draft',
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    ordered_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    ordered_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
    quantity NUMERIC(10,3) NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.5 Menus & Weekly Plans
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    date DATE NOT NULL,
    meal_type meal_type NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    is_main_course BOOLEAN NOT NULL DEFAULT false,
    max_quantity INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS weekly_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    is_validated BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS weekly_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
    menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.6 QR Codes
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qr_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    code TEXT NOT NULL UNIQUE,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until TIMESTAMPTZ,
    is_single_use BOOLEAN NOT NULL DEFAULT false,
    is_used BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS qr_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    qr_code_id UUID NOT NULL REFERENCES qr_codes(id) ON DELETE CASCADE,
    scanned_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    location TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.7 Orders
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    menu_id UUID REFERENCES menus(id) ON DELETE SET NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status order_status_type NOT NULL DEFAULT 'pending',
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    notes TEXT,
    qr_code_id UUID REFERENCES qr_codes(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.8 Physical Tickets
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS physical_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    ticket_number TEXT NOT NULL UNIQUE,
    value NUMERIC(10,2) NOT NULL DEFAULT 0,
    status ticket_status_type NOT NULL DEFAULT 'active',
    used_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.9 Production
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
    planned_quantity INTEGER NOT NULL DEFAULT 0,
    produced_quantity INTEGER NOT NULL DEFAULT 0,
    production_date DATE NOT NULL DEFAULT CURRENT_DATE,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    supervised_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.10 Drivers & Deliveries
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    vehicle_info TEXT,
    license_plate TEXT,
    is_available BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    site_id UUID REFERENCES company_sites(id) ON DELETE SET NULL,
    status delivery_status_type NOT NULL DEFAULT 'pending',
    scheduled_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    signature_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS delivery_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    temperature_check NUMERIC(4,1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.11 Formulas
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS formulas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL DEFAULT 0,
    dishes_included INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.12 Invoicing & Payments
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    invoice_number TEXT NOT NULL UNIQUE,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status payment_status_type NOT NULL DEFAULT 'pending',
    due_date DATE NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    quantity NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit_price NUMERIC(10,2) NOT NULL DEFAULT 0,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_employee_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    meals_count INTEGER NOT NULL DEFAULT 0,
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_method payment_method_type NOT NULL,
    reference TEXT,
    paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    amount_applied NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.13 Notifications
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT,
    type TEXT,
    is_read BOOLEAN NOT NULL DEFAULT false,
    action_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.14 Audit Logs
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    table_name TEXT,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- --------------------------------------------------------------------------
-- 3.15 App Config
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS app_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL UNIQUE,
    value TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 4. INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_site_id ON profiles(site_id);
CREATE INDEX IF NOT EXISTS idx_profiles_is_active ON profiles(is_active);

-- User roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_granted_by ON user_roles(granted_by);

-- Companies indexes
CREATE INDEX IF NOT EXISTS idx_companies_code ON companies(code);
CREATE INDEX IF NOT EXISTS idx_companies_is_active ON companies(is_active);

-- Company sites indexes
CREATE INDEX IF NOT EXISTS idx_company_sites_company_id ON company_sites(company_id);

-- Company contracts indexes
CREATE INDEX IF NOT EXISTS idx_company_contracts_company_id ON company_contracts(company_id);
CREATE INDEX IF NOT EXISTS idx_company_contracts_is_active ON company_contracts(is_active);
CREATE INDEX IF NOT EXISTS idx_company_contracts_start_date ON company_contracts(start_date);
CREATE INDEX IF NOT EXISTS idx_company_contracts_end_date ON company_contracts(end_date);

-- Dishes indexes
CREATE INDEX IF NOT EXISTS idx_dishes_category ON dishes(category);
CREATE INDEX IF NOT EXISTS idx_dishes_is_available ON dishes(is_available);

-- Ingredients indexes
CREATE INDEX IF NOT EXISTS idx_ingredients_category ON ingredients(category);

-- Dish ingredients indexes
CREATE INDEX IF NOT EXISTS idx_dish_ingredients_dish_id ON dish_ingredients(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_ingredients_ingredient_id ON dish_ingredients(ingredient_id);

-- Dish allergens indexes
CREATE INDEX IF NOT EXISTS idx_dish_allergens_dish_id ON dish_allergens(dish_id);

-- Dish ratings indexes
CREATE INDEX IF NOT EXISTS idx_dish_ratings_dish_id ON dish_ratings(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_ratings_user_id ON dish_ratings(user_id);

-- Suppliers indexes
CREATE INDEX IF NOT EXISTS idx_suppliers_is_active ON suppliers(is_active);

-- Supplier ingredients indexes
CREATE INDEX IF NOT EXISTS idx_supplier_ingredients_supplier_id ON supplier_ingredients(supplier_id);
CREATE INDEX IF NOT EXISTS idx_supplier_ingredients_ingredient_id ON supplier_ingredients(ingredient_id);

-- Stock movements indexes
CREATE INDEX IF NOT EXISTS idx_stock_movements_ingredient_id ON stock_movements(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_stock_movements_movement_type ON stock_movements(movement_type);
CREATE INDEX IF NOT EXISTS idx_stock_movements_performed_by ON stock_movements(performed_by);
CREATE INDEX IF NOT EXISTS idx_stock_movements_created_at ON stock_movements(created_at);

-- Purchase orders indexes
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_ordered_by ON purchase_orders(ordered_by);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_ordered_at ON purchase_orders(ordered_at);

-- Purchase order items indexes
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_purchase_order_id ON purchase_order_items(purchase_order_id);
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_ingredient_id ON purchase_order_items(ingredient_id);

-- Menus indexes
CREATE INDEX IF NOT EXISTS idx_menus_date ON menus(date);
CREATE INDEX IF NOT EXISTS idx_menus_meal_type ON menus(meal_type);
CREATE INDEX IF NOT EXISTS idx_menus_is_published ON menus(is_published);

-- Menu items indexes
CREATE INDEX IF NOT EXISTS idx_menu_items_menu_id ON menu_items(menu_id);
CREATE INDEX IF NOT EXISTS idx_menu_items_dish_id ON menu_items(dish_id);

-- Weekly plans indexes
CREATE INDEX IF NOT EXISTS idx_weekly_plans_company_id ON weekly_plans(company_id);
CREATE INDEX IF NOT EXISTS idx_weekly_plans_week_start_date ON weekly_plans(week_start_date);

-- Weekly plan items indexes
CREATE INDEX IF NOT EXISTS idx_weekly_plan_items_weekly_plan_id ON weekly_plan_items(weekly_plan_id);
CREATE INDEX IF NOT EXISTS idx_weekly_plan_items_menu_id ON weekly_plan_items(menu_id);

-- QR codes indexes
CREATE INDEX IF NOT EXISTS idx_qr_codes_user_id ON qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_code ON qr_codes(code);
CREATE INDEX IF NOT EXISTS idx_qr_codes_valid_from ON qr_codes(valid_from);
CREATE INDEX IF NOT EXISTS idx_qr_codes_valid_until ON qr_codes(valid_until);

-- QR scans indexes
CREATE INDEX IF NOT EXISTS idx_qr_scans_qr_code_id ON qr_scans(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_by ON qr_scans(scanned_by);
CREATE INDEX IF NOT EXISTS idx_qr_scans_scanned_at ON qr_scans(scanned_at);

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_menu_id ON orders(menu_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_qr_code_id ON orders(qr_code_id);

-- Physical tickets indexes
CREATE INDEX IF NOT EXISTS idx_physical_tickets_company_id ON physical_tickets(company_id);
CREATE INDEX IF NOT EXISTS idx_physical_tickets_ticket_number ON physical_tickets(ticket_number);
CREATE INDEX IF NOT EXISTS idx_physical_tickets_status ON physical_tickets(status);
CREATE INDEX IF NOT EXISTS idx_physical_tickets_used_by ON physical_tickets(used_by);

-- Production batches indexes
CREATE INDEX IF NOT EXISTS idx_production_batches_menu_id ON production_batches(menu_id);
CREATE INDEX IF NOT EXISTS idx_production_batches_production_date ON production_batches(production_date);
CREATE INDEX IF NOT EXISTS idx_production_batches_supervised_by ON production_batches(supervised_by);

-- Drivers indexes
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_is_available ON drivers(is_available);

-- Deliveries indexes
CREATE INDEX IF NOT EXISTS idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_company_id ON deliveries(company_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_site_id ON deliveries(site_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_scheduled_at ON deliveries(scheduled_at);

-- Delivery items indexes
CREATE INDEX IF NOT EXISTS idx_delivery_items_delivery_id ON delivery_items(delivery_id);
CREATE INDEX IF NOT EXISTS idx_delivery_items_dish_id ON delivery_items(dish_id);

-- Invoices indexes
CREATE INDEX IF NOT EXISTS idx_invoices_company_id ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_period_start ON invoices(period_start);
CREATE INDEX IF NOT EXISTS idx_invoices_period_end ON invoices(period_end);

-- Invoice items indexes
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice_id ON invoice_items(invoice_id);

-- Invoice employee details indexes
CREATE INDEX IF NOT EXISTS idx_invoice_employee_details_invoice_id ON invoice_employee_details(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_employee_details_employee_id ON invoice_employee_details(employee_id);

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_method ON payments(payment_method);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);

-- Invoice payments indexes
CREATE INDEX IF NOT EXISTS idx_invoice_payments_invoice_id ON invoice_payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_payments_payment_id ON invoice_payments(payment_id);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Audit logs indexes
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_record_id ON audit_logs(record_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- App config indexes
CREATE INDEX IF NOT EXISTS idx_app_config_key ON app_config(key);

-- Formulas indexes
CREATE INDEX IF NOT EXISTS idx_formulas_is_active ON formulas(is_active);

-- ============================================================================
-- 5. UPDATED_AT TRIGGER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to ALL tables
DO $$ 
DECLARE
    t TEXT;
    tables TEXT[] := ARRAY[
        'profiles', 'user_roles', 'companies', 'company_sites', 'company_contracts',
        'dishes', 'ingredients', 'dish_ingredients', 'dish_allergens', 'dish_ratings',
        'suppliers', 'supplier_ingredients', 'stock_movements', 'purchase_orders',
        'purchase_order_items', 'menus', 'menu_items', 'weekly_plans', 'weekly_plan_items',
        'orders', 'qr_codes', 'qr_scans', 'physical_tickets', 'production_batches',
        'drivers', 'deliveries', 'delivery_items', 'formulas', 'invoices', 'invoice_items',
        'invoice_employee_details', 'payments', 'invoice_payments', 'notifications',
        'audit_logs', 'app_config'
    ];
BEGIN
    FOREACH t IN ARRAY tables LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trigger_update_%I_updated_at ON %I; CREATE TRIGGER trigger_update_%I_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ============================================================================
-- 6. AUDIT LOG TRIGGER FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION audit_log_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id UUID;
    action_text TEXT;
    old_row JSONB := NULL;
    new_row JSONB := NULL;
    rec_id UUID;
BEGIN
    -- Try to get the current user from Supabase auth
    BEGIN
        current_user_id := auth.uid();
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;

    IF TG_OP = 'INSERT' THEN
        action_text := 'INSERT';
        new_row := to_jsonb(NEW);
        rec_id := NEW.id;
    ELSIF TG_OP = 'UPDATE' THEN
        action_text := 'UPDATE';
        old_row := to_jsonb(OLD);
        new_row := to_jsonb(NEW);
        rec_id := NEW.id;
    ELSIF TG_OP = 'DELETE' THEN
        action_text := 'DELETE';
        old_row := to_jsonb(OLD);
        rec_id := OLD.id;
    END IF;

    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data)
    VALUES (current_user_id, action_text, TG_TABLE_NAME, rec_id, old_row, new_row);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit trigger to key tables
DO $$
DECLARE
    t TEXT;
    audit_tables TEXT[] := ARRAY['orders', 'invoices', 'payments', 'deliveries'];
BEGIN
    FOREACH t IN ARRAY audit_tables LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trigger_audit_%I ON %I; CREATE TRIGGER trigger_audit_%I AFTER INSERT OR UPDATE OR DELETE ON %I FOR EACH ROW EXECUTE FUNCTION audit_log_trigger_function();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ============================================================================
-- 7. ROW LEVEL SECURITY
-- ============================================================================

-- Helper function: check if user has a specific role
CREATE OR REPLACE FUNCTION has_role(required_role user_role_type)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
        AND role = required_role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper function: check if user is any admin type
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
        AND role IN ('superadmin', 'milys_admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper function: check if user is company admin for a specific company
CREATE OR REPLACE FUNCTION is_company_admin(target_company_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles ur
        JOIN profiles p ON p.id = ur.user_id
        WHERE ur.user_id = auth.uid()
        AND ur.role = 'company_admin'
        AND p.company_id = target_company_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Helper function: check if user is any Mily's staff
CREATE OR REPLACE FUNCTION is_milys_staff()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid()
        AND role IN ('superadmin', 'milys_admin', 'milys_kitchen', 'milys_logistics', 'milys_cashier')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- -------------------------------------------------------
-- Enable RLS on ALL tables
-- -------------------------------------------------------
DO $$
DECLARE
    t TEXT;
    all_tables TEXT[] := ARRAY[
        'profiles', 'user_roles', 'companies', 'company_sites', 'company_contracts',
        'dishes', 'ingredients', 'dish_ingredients', 'dish_allergens', 'dish_ratings',
        'suppliers', 'supplier_ingredients', 'stock_movements', 'purchase_orders',
        'purchase_order_items', 'menus', 'menu_items', 'weekly_plans', 'weekly_plan_items',
        'orders', 'qr_codes', 'qr_scans', 'physical_tickets', 'production_batches',
        'drivers', 'deliveries', 'delivery_items', 'formulas', 'invoices', 'invoice_items',
        'invoice_employee_details', 'payments', 'invoice_payments', 'notifications',
        'audit_logs', 'app_config'
    ];
BEGIN
    FOREACH t IN ARRAY all_tables LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', t);
    END LOOP;
END $$;

-- -------------------------------------------------------
-- PROFILES policies
-- -------------------------------------------------------
CREATE POLICY "profiles_select_own"
    ON profiles FOR SELECT
    TO authenticated
    USING (id = auth.uid());

CREATE POLICY "profiles_select_admin"
    ON profiles FOR SELECT
    TO authenticated
    USING (is_admin());

CREATE POLICY "profiles_select_company_admin"
    ON profiles FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles ur
            JOIN profiles admin_p ON admin_p.id = ur.user_id
            WHERE ur.user_id = auth.uid()
            AND ur.role = 'company_admin'
            AND admin_p.company_id = profiles.company_id
        )
    );

CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_admin_all"
    ON profiles FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

-- -------------------------------------------------------
-- ORDERS policies
-- -------------------------------------------------------
CREATE POLICY "orders_select_own"
    ON orders FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "orders_insert_own"
    ON orders FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "orders_update_own"
    ON orders FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "orders_admin_all"
    ON orders FOR ALL
    TO authenticated
    USING (is_admin() OR is_milys_staff())
    WITH CHECK (is_admin() OR is_milys_staff());

-- -------------------------------------------------------
-- COMPANIES policies
-- -------------------------------------------------------
CREATE POLICY "companies_select_authenticated"
    ON companies FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "companies_manage_company_admin"
    ON companies FOR UPDATE
    TO authenticated
    USING (is_company_admin(id))
    WITH CHECK (is_company_admin(id));

CREATE POLICY "companies_admin_all"
    ON companies FOR ALL
    TO authenticated
    USING (is_admin())
    WITH CHECK (is_admin());

-- -------------------------------------------------------
-- Generic read-for-authenticated, write-for-admin policies
-- Applied to all other tables
-- -------------------------------------------------------

-- USER_ROLES
CREATE POLICY "user_roles_select_own"
    ON user_roles FOR SELECT TO authenticated
    USING (user_id = auth.uid());
CREATE POLICY "user_roles_admin_all"
    ON user_roles FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- COMPANY_SITES
CREATE POLICY "company_sites_select"
    ON company_sites FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "company_sites_admin_manage"
    ON company_sites FOR ALL TO authenticated
    USING (is_admin() OR is_company_admin(company_id))
    WITH CHECK (is_admin() OR is_company_admin(company_id));

-- COMPANY_CONTRACTS
CREATE POLICY "company_contracts_select"
    ON company_contracts FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "company_contracts_admin_manage"
    ON company_contracts FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- DISHES
CREATE POLICY "dishes_select"
    ON dishes FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "dishes_admin_manage"
    ON dishes FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- INGREDIENTS
CREATE POLICY "ingredients_select"
    ON ingredients FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "ingredients_admin_manage"
    ON ingredients FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- DISH_INGREDIENTS
CREATE POLICY "dish_ingredients_select"
    ON dish_ingredients FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "dish_ingredients_admin_manage"
    ON dish_ingredients FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- DISH_ALLERGENS
CREATE POLICY "dish_allergens_select"
    ON dish_allergens FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "dish_allergens_admin_manage"
    ON dish_allergens FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- DISH_RATINGS
CREATE POLICY "dish_ratings_select"
    ON dish_ratings FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "dish_ratings_insert_own"
    ON dish_ratings FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());
CREATE POLICY "dish_ratings_update_own"
    ON dish_ratings FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "dish_ratings_admin_manage"
    ON dish_ratings FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- SUPPLIERS
CREATE POLICY "suppliers_select"
    ON suppliers FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "suppliers_admin_manage"
    ON suppliers FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- SUPPLIER_INGREDIENTS
CREATE POLICY "supplier_ingredients_select"
    ON supplier_ingredients FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "supplier_ingredients_admin_manage"
    ON supplier_ingredients FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- STOCK_MOVEMENTS
CREATE POLICY "stock_movements_select"
    ON stock_movements FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "stock_movements_admin_manage"
    ON stock_movements FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- PURCHASE_ORDERS
CREATE POLICY "purchase_orders_select"
    ON purchase_orders FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "purchase_orders_admin_manage"
    ON purchase_orders FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- PURCHASE_ORDER_ITEMS
CREATE POLICY "purchase_order_items_select"
    ON purchase_order_items FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "purchase_order_items_admin_manage"
    ON purchase_order_items FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- MENUS
CREATE POLICY "menus_select"
    ON menus FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "menus_admin_manage"
    ON menus FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- MENU_ITEMS
CREATE POLICY "menu_items_select"
    ON menu_items FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "menu_items_admin_manage"
    ON menu_items FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- WEEKLY_PLANS
CREATE POLICY "weekly_plans_select"
    ON weekly_plans FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "weekly_plans_admin_manage"
    ON weekly_plans FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- WEEKLY_PLAN_ITEMS
CREATE POLICY "weekly_plan_items_select"
    ON weekly_plan_items FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "weekly_plan_items_admin_manage"
    ON weekly_plan_items FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- QR_CODES
CREATE POLICY "qr_codes_select_own"
    ON qr_codes FOR SELECT TO authenticated
    USING (user_id = auth.uid());
CREATE POLICY "qr_codes_admin_all"
    ON qr_codes FOR ALL TO authenticated
    USING (is_admin() OR is_milys_staff())
    WITH CHECK (is_admin() OR is_milys_staff());

-- QR_SCANS
CREATE POLICY "qr_scans_select"
    ON qr_scans FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "qr_scans_admin_manage"
    ON qr_scans FOR ALL TO authenticated
    USING (is_admin() OR is_milys_staff())
    WITH CHECK (is_admin() OR is_milys_staff());

-- PHYSICAL_TICKETS
CREATE POLICY "physical_tickets_select"
    ON physical_tickets FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "physical_tickets_admin_manage"
    ON physical_tickets FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- PRODUCTION_BATCHES
CREATE POLICY "production_batches_select"
    ON production_batches FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "production_batches_admin_manage"
    ON production_batches FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_kitchen'))
    WITH CHECK (is_admin() OR has_role('milys_kitchen'));

-- DRIVERS
CREATE POLICY "drivers_select"
    ON drivers FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "drivers_admin_manage"
    ON drivers FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_logistics'))
    WITH CHECK (is_admin() OR has_role('milys_logistics'));

-- DELIVERIES
CREATE POLICY "deliveries_select"
    ON deliveries FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "deliveries_admin_manage"
    ON deliveries FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_logistics'))
    WITH CHECK (is_admin() OR has_role('milys_logistics'));

-- DELIVERY_ITEMS
CREATE POLICY "delivery_items_select"
    ON delivery_items FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "delivery_items_admin_manage"
    ON delivery_items FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_logistics'))
    WITH CHECK (is_admin() OR has_role('milys_logistics'));

-- FORMULAS
CREATE POLICY "formulas_select"
    ON formulas FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "formulas_admin_manage"
    ON formulas FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- INVOICES
CREATE POLICY "invoices_select"
    ON invoices FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "invoices_admin_manage"
    ON invoices FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- INVOICE_ITEMS
CREATE POLICY "invoice_items_select"
    ON invoice_items FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "invoice_items_admin_manage"
    ON invoice_items FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- INVOICE_EMPLOYEE_DETAILS
CREATE POLICY "invoice_employee_details_select"
    ON invoice_employee_details FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "invoice_employee_details_admin_manage"
    ON invoice_employee_details FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- PAYMENTS
CREATE POLICY "payments_select"
    ON payments FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "payments_admin_manage"
    ON payments FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- INVOICE_PAYMENTS
CREATE POLICY "invoice_payments_select"
    ON invoice_payments FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "invoice_payments_admin_manage"
    ON invoice_payments FOR ALL TO authenticated
    USING (is_admin() OR has_role('milys_cashier'))
    WITH CHECK (is_admin() OR has_role('milys_cashier'));

-- NOTIFICATIONS
CREATE POLICY "notifications_select_own"
    ON notifications FOR SELECT TO authenticated
    USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own"
    ON notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "notifications_admin_all"
    ON notifications FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- AUDIT_LOGS
CREATE POLICY "audit_logs_select"
    ON audit_logs FOR SELECT TO authenticated
    USING (is_admin());
CREATE POLICY "audit_logs_insert"
    ON audit_logs FOR INSERT TO authenticated
    WITH CHECK (true);

-- APP_CONFIG
CREATE POLICY "app_config_select"
    ON app_config FOR SELECT TO authenticated
    USING (true);
CREATE POLICY "app_config_admin_manage"
    ON app_config FOR ALL TO authenticated
    USING (is_admin()) WITH CHECK (is_admin());

-- ============================================================================
-- 8. SEED DATA
-- ============================================================================

-- -------------------------------------------------------
-- 8.1 Companies
-- -------------------------------------------------------
INSERT INTO companies (id, name, code, address, city, contact_name, contact_email, contact_phone) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Bolloré Transport & Logistics', 'BTL-CMR', 'Boulevard de la Liberté, BP 4057', 'Douala', 'Jean-Pierre Kamga', 'jp.kamga@bollore.com', '+237 233 42 80 00'),
    ('a0000000-0000-0000-0000-000000000002', 'Orange Cameroun', 'ORC-CMR', 'Rue Ivy, Akwa, BP 1614', 'Douala', 'Marie-Claire Ngo Bassa', 'mc.ngobassa@orange.cm', '+237 699 00 00 00'),
    ('a0000000-0000-0000-0000-000000000003', 'Société Générale Cameroun', 'SGC-CMR', '78 Rue Joss, BP 4042', 'Douala', 'Paul Essomba Mbida', 'p.essomba@socgen.cm', '+237 233 42 73 00')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.2 Company Sites (2 per company)
-- -------------------------------------------------------
INSERT INTO company_sites (id, company_id, name, address, city) VALUES
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Siège Douala - Bolloré', 'Boulevard de la Liberté', 'Douala'),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Agence Yaoundé - Bolloré', 'Avenue Kennedy, Quartier Hippodrome', 'Yaoundé'),
    ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'Siège Orange Akwa', 'Rue Ivy, Akwa', 'Douala'),
    ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000002', 'Agence Orange Bastos', 'Rue Joseph Mballa Eloumden, Bastos', 'Yaoundé'),
    ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000003', 'Siège SG Bonanjo', '78 Rue Joss, Bonanjo', 'Douala'),
    ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000003', 'Agence SG Centre-Ville', 'Place Ahmadou Ahidjo', 'Yaoundé')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.3 Company Contracts
-- -------------------------------------------------------
INSERT INTO company_contracts (company_id, contract_type, start_date, end_date, daily_budget_per_employee, meal_types_included, is_active) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'forfait', '2026-01-01', '2026-12-31', 3500.00, ARRAY['dejeuner'], true),
    ('a0000000-0000-0000-0000-000000000002', 'mixed', '2026-01-01', '2026-12-31', 4000.00, ARRAY['dejeuner', 'collation'], true),
    ('a0000000-0000-0000-0000-000000000003', 'a_la_carte', '2026-02-01', '2027-01-31', 5000.00, ARRAY['petit_dejeuner', 'dejeuner'], true)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.4 Dishes (Cameroonian cuisine, prices in FCFA)
-- -------------------------------------------------------
INSERT INTO dishes (id, name, description, category, base_price, is_available, preparation_time_min, calories, is_vegetarian, is_vegan) VALUES
    ('d0000000-0000-0000-0000-000000000001', 'Ndolé', 'Plat traditionnel à base de feuilles de ndolé, crevettes, arachides et viande. Servi avec plantain ou miondo.', 'Plat principal', 2500.00, true, 90, 650, false, false),
    ('d0000000-0000-0000-0000-000000000002', 'Eru', 'Soupe épaisse à base de feuilles d''eru (okok) et de waterleaf, accompagnée de garri ou fufu.', 'Plat principal', 2000.00, true, 60, 500, false, false),
    ('d0000000-0000-0000-0000-000000000003', 'Poulet DG', 'Poulet braisé sauté avec des plantains mûrs frits, légumes et épices du terroir.', 'Plat principal', 3500.00, true, 45, 750, false, false),
    ('d0000000-0000-0000-0000-000000000004', 'Poisson braisé', 'Bar ou maquereau braisé au charbon, mariné aux épices locales, servi avec miondo et sauce tomate pimentée.', 'Plat principal', 3000.00, true, 40, 550, false, false),
    ('d0000000-0000-0000-0000-000000000005', 'Beignets haricots', 'Beignets frits à base de haricots blancs mixés et épicés, accompagnés de bouillie de maïs.', 'Petit déjeuner', 500.00, true, 25, 350, true, true),
    ('d0000000-0000-0000-0000-000000000006', 'Koki', 'Gâteau de haricots cornilles enveloppé dans des feuilles de bananier, cuit à la vapeur.', 'Accompagnement', 1000.00, true, 60, 400, true, true),
    ('d0000000-0000-0000-0000-000000000007', 'Mbongo Tchobi', 'Poisson ou viande mijoté dans une sauce noire à base d''épices brûlées (mbongo). Saveur intense et unique.', 'Plat principal', 3000.00, true, 75, 600, false, false),
    ('d0000000-0000-0000-0000-000000000008', 'Achu Soup', 'Soupe jaune à base de calcaire, accompagnée de taro pilé (achu). Spécialité du Nord-Ouest.', 'Plat principal', 2000.00, true, 50, 550, false, false),
    ('d0000000-0000-0000-0000-000000000009', 'Kondré', 'Ragoût de plantain vert mijoté avec de la chèvre ou du bœuf et des épices.', 'Plat principal', 2500.00, true, 60, 600, false, false),
    ('d0000000-0000-0000-0000-000000000010', 'Riz sauté aux légumes', 'Riz sauté avec carottes, haricots verts, poivrons et oignons. Option végétarienne disponible.', 'Accompagnement', 1500.00, true, 20, 400, true, true),
    ('d0000000-0000-0000-0000-000000000011', 'Sauce gombo', 'Sauce gluante à base de gombo frais, servie avec du couscous de manioc ou du riz.', 'Plat principal', 2000.00, true, 35, 450, false, false),
    ('d0000000-0000-0000-0000-000000000012', 'Taro sauce jaune', 'Tubercule de taro cuit et servi avec une sauce jaune onctueuse au jus de palme et légumes.', 'Plat principal', 1800.00, true, 45, 500, false, false),
    ('d0000000-0000-0000-0000-000000000013', 'Soya (brochettes)', 'Brochettes de bœuf grillées, marinées au suya spice et servies avec oignons et piment.', 'Entrée', 1500.00, true, 20, 350, false, false),
    ('d0000000-0000-0000-0000-000000000014', 'Bâton de manioc (Miondo)', 'Bâtons de manioc fermenté et cuit dans des feuilles. Accompagnement traditionnel.', 'Accompagnement', 300.00, true, 15, 200, true, true),
    ('d0000000-0000-0000-0000-000000000015', 'Jus de Foléré', 'Boisson rafraîchissante à base de fleurs d''hibiscus (bissap), sucrée et parfumée.', 'Boisson', 500.00, true, 10, 120, true, true)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.5 Ingredients
-- -------------------------------------------------------
INSERT INTO ingredients (id, name, unit, unit_price, stock_quantity, min_stock_threshold, category) VALUES
    ('e0000000-0000-0000-0000-000000000001', 'Feuilles de ndolé', 'kg', 1500.00, 50.0, 10.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000002', 'Crevettes séchées', 'kg', 5000.00, 20.0, 5.0, 'Fruits de mer'),
    ('e0000000-0000-0000-0000-000000000003', 'Arachides crues', 'kg', 800.00, 40.0, 10.0, 'Légumineuses'),
    ('e0000000-0000-0000-0000-000000000004', 'Plantain mûr', 'kg', 500.00, 100.0, 20.0, 'Féculents'),
    ('e0000000-0000-0000-0000-000000000005', 'Poulet entier', 'unité', 3500.00, 60.0, 15.0, 'Viandes'),
    ('e0000000-0000-0000-0000-000000000006', 'Bar (poisson)', 'kg', 3000.00, 30.0, 8.0, 'Poissons'),
    ('e0000000-0000-0000-0000-000000000007', 'Feuilles d''eru (okok)', 'kg', 2000.00, 25.0, 5.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000008', 'Waterleaf', 'kg', 500.00, 30.0, 8.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000009', 'Huile de palme', 'litre', 1000.00, 50.0, 15.0, 'Huiles'),
    ('e0000000-0000-0000-0000-000000000010', 'Oignon', 'kg', 600.00, 40.0, 10.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000011', 'Tomate fraîche', 'kg', 700.00, 35.0, 10.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000012', 'Piment', 'kg', 1200.00, 10.0, 3.0, 'Épices'),
    ('e0000000-0000-0000-0000-000000000013', 'Riz long grain', 'kg', 600.00, 200.0, 50.0, 'Féculents'),
    ('e0000000-0000-0000-0000-000000000014', 'Manioc', 'kg', 300.00, 80.0, 20.0, 'Féculents'),
    ('e0000000-0000-0000-0000-000000000015', 'Haricots blancs', 'kg', 900.00, 30.0, 10.0, 'Légumineuses'),
    ('e0000000-0000-0000-0000-000000000016', 'Bœuf (viande)', 'kg', 4000.00, 40.0, 10.0, 'Viandes'),
    ('e0000000-0000-0000-0000-000000000017', 'Gombo frais', 'kg', 800.00, 20.0, 5.0, 'Légumes'),
    ('e0000000-0000-0000-0000-000000000018', 'Taro', 'kg', 500.00, 30.0, 8.0, 'Féculents'),
    ('e0000000-0000-0000-0000-000000000019', 'Fleurs de Foléré (hibiscus)', 'kg', 2500.00, 10.0, 3.0, 'Boissons'),
    ('e0000000-0000-0000-0000-000000000020', 'Sucre', 'kg', 700.00, 50.0, 15.0, 'Épicerie')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.6 Dish Ingredients (linking dishes to ingredients)
-- -------------------------------------------------------
INSERT INTO dish_ingredients (dish_id, ingredient_id, quantity_needed) VALUES
    -- Ndolé
    ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 0.500),
    ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', 0.200),
    ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003', 0.300),
    ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000004', 0.400),
    -- Eru
    ('d0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000007', 0.400),
    ('d0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000008', 0.300),
    ('d0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000009', 0.100),
    -- Poulet DG
    ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000005', 1.000),
    ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000004', 0.500),
    ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000010', 0.200),
    ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000011', 0.300),
    -- Poisson braisé
    ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000006', 0.600),
    ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000012', 0.050),
    ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000014', 0.300),
    -- Riz sauté
    ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000013', 0.400),
    ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000010', 0.150),
    ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000011', 0.200),
    -- Jus de Foléré
    ('d0000000-0000-0000-0000-000000000015', 'e0000000-0000-0000-0000-000000000019', 0.050),
    ('d0000000-0000-0000-0000-000000000015', 'e0000000-0000-0000-0000-000000000020', 0.100)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.7 Dish Allergens
-- -------------------------------------------------------
INSERT INTO dish_allergens (dish_id, allergen_name) VALUES
    ('d0000000-0000-0000-0000-000000000001', 'Arachides'),
    ('d0000000-0000-0000-0000-000000000001', 'Crustacés'),
    ('d0000000-0000-0000-0000-000000000002', 'Huile de palme'),
    ('d0000000-0000-0000-0000-000000000004', 'Poisson'),
    ('d0000000-0000-0000-0000-000000000005', 'Gluten'),
    ('d0000000-0000-0000-0000-000000000006', 'Légumineuses')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.8 Suppliers
-- -------------------------------------------------------
INSERT INTO suppliers (id, name, contact_name, phone, email, address, city, is_active) VALUES
    ('f0000000-0000-0000-0000-000000000001', 'Marché Central Douala SARL', 'Amina Bello', '+237 677 12 34 56', 'contact@marchecentraldla.cm', 'Marché Central, Akwa', 'Douala', true),
    ('f0000000-0000-0000-0000-000000000002', 'AgroCam Supplies', 'Emmanuel Tabi', '+237 699 98 76 54', 'info@agrocam.cm', 'Zone Industrielle Bonabéri', 'Douala', true),
    ('f0000000-0000-0000-0000-000000000003', 'Pêcheries du Wouri', 'Gaston Njike', '+237 655 44 33 22', 'commandes@pecheries-wouri.cm', 'Port de pêche, Deido', 'Douala', true)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.9 Supplier Ingredients
-- -------------------------------------------------------
INSERT INTO supplier_ingredients (supplier_id, ingredient_id, supply_price, delivery_delay_days) VALUES
    ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 1400.00, 1),
    ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000004', 450.00, 1),
    ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000010', 550.00, 1),
    ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000011', 650.00, 1),
    ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000012', 1100.00, 1),
    ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000013', 550.00, 2),
    ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000009', 900.00, 2),
    ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000020', 650.00, 2),
    ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', 750.00, 2),
    ('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000006', 2800.00, 1),
    ('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000002', 4800.00, 1)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.10 Menus (Monday to Friday, lunch for one week)
-- -------------------------------------------------------
INSERT INTO menus (id, name, date, meal_type, is_published) VALUES
    ('c0000000-0000-0000-0000-000000000001', 'Menu Lundi - Semaine 9', '2026-02-23', 'dejeuner', true),
    ('c0000000-0000-0000-0000-000000000002', 'Menu Mardi - Semaine 9', '2026-02-24', 'dejeuner', true),
    ('c0000000-0000-0000-0000-000000000003', 'Menu Mercredi - Semaine 9', '2026-02-25', 'dejeuner', true),
    ('c0000000-0000-0000-0000-000000000004', 'Menu Jeudi - Semaine 9', '2026-02-26', 'dejeuner', true),
    ('c0000000-0000-0000-0000-000000000005', 'Menu Vendredi - Semaine 9', '2026-02-27', 'dejeuner', true)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.11 Menu Items (3-4 dishes per menu)
-- -------------------------------------------------------
INSERT INTO menu_items (menu_id, dish_id, is_main_course, max_quantity) VALUES
    -- Lundi: Ndolé + Riz sauté + Jus Foléré
    ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', true, 80),
    ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000010', false, 80),
    ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000015', false, 100),
    -- Mardi: Poulet DG + Soya + Jus Foléré
    ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000003', true, 70),
    ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000013', false, 50),
    ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000015', false, 100),
    -- Mercredi: Poisson braisé + Miondo + Koki
    ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000004', true, 75),
    ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000014', false, 80),
    ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000006', false, 60),
    -- Jeudi: Eru + Sauce gombo + Riz sauté
    ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000002', true, 70),
    ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000011', true, 60),
    ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000010', false, 80),
    -- Vendredi: Mbongo Tchobi + Kondré + Jus Foléré
    ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000007', true, 65),
    ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000009', true, 60),
    ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000015', false, 100)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.12 Weekly Plan
-- -------------------------------------------------------
INSERT INTO weekly_plans (id, week_start_date, week_end_date, company_id, is_validated) VALUES
    ('wp000000-0000-0000-0000-000000000001', '2026-02-23', '2026-02-27', 'a0000000-0000-0000-0000-000000000001', true),
    ('wp000000-0000-0000-0000-000000000002', '2026-02-23', '2026-02-27', 'a0000000-0000-0000-0000-000000000002', true),
    ('wp000000-0000-0000-0000-000000000003', '2026-02-23', '2026-02-27', 'a0000000-0000-0000-0000-000000000003', true)
ON CONFLICT DO NOTHING;

INSERT INTO weekly_plan_items (weekly_plan_id, menu_id, day_of_week) VALUES
    -- Bolloré
    ('wp000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 1),
    ('wp000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 2),
    ('wp000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 3),
    ('wp000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 4),
    ('wp000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 5),
    -- Orange
    ('wp000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 1),
    ('wp000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000002', 2),
    ('wp000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003', 3),
    ('wp000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000004', 4),
    ('wp000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000005', 5),
    -- Société Générale
    ('wp000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 1),
    ('wp000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', 2),
    ('wp000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000003', 3),
    ('wp000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000004', 4),
    ('wp000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', 5)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.13 Formulas
-- -------------------------------------------------------
INSERT INTO formulas (name, description, price, dishes_included, is_active) VALUES
    ('Formule Économique', 'Un plat principal + une boisson', 2500.00, 2, true),
    ('Formule Standard', 'Une entrée + un plat principal + une boisson', 3500.00, 3, true),
    ('Formule Premium', 'Une entrée + un plat principal + un accompagnement + une boisson + un dessert', 5000.00, 5, true)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.14 App Config
-- -------------------------------------------------------
INSERT INTO app_config (key, value, description) VALUES
    ('app_name', 'MILY''S', 'Nom de l''application'),
    ('currency', 'FCFA', 'Devise utilisée'),
    ('default_language', 'fr', 'Langue par défaut'),
    ('tax_rate', '19.25', 'Taux de TVA en pourcentage'),
    ('order_cutoff_time', '10:00', 'Heure limite de commande (format HH:MM)'),
    ('delivery_start_time', '11:30', 'Heure de début de livraison'),
    ('delivery_end_time', '14:00', 'Heure de fin de livraison'),
    ('max_orders_per_user_per_day', '2', 'Nombre maximum de commandes par utilisateur par jour'),
    ('qr_code_validity_hours', '24', 'Durée de validité des QR codes en heures'),
    ('company_name', 'MILY''S Restauration', 'Raison sociale'),
    ('company_address', 'Rue de la Joie, Bonapriso, Douala', 'Adresse de l''entreprise'),
    ('company_phone', '+237 233 00 00 00', 'Téléphone principal'),
    ('company_email', 'contact@milys-restauration.cm', 'Email de contact')
ON CONFLICT (key) DO NOTHING;

-- -------------------------------------------------------
-- 8.15 Employee Profiles (20 employees with Cameroonian names)
-- Note: In a real Supabase deployment, profiles reference auth.users.
-- For seed data, we insert directly with gen_random_uuid() IDs.
-- In production, these would be created via Supabase Auth signup.
-- We temporarily disable the FK constraint to profiles for seeding,
-- then re-enable it, OR we insert into auth.users first.
-- Here we use a DO block that handles the auth.users dependency.
-- -------------------------------------------------------

-- Create a helper function to safely seed profiles
-- This inserts into auth.users if the table exists, then into profiles
DO $$
DECLARE
    emp RECORD;
BEGIN
    -- Define employee data
    FOR emp IN
        SELECT * FROM (VALUES
            ('10000000-0000-0000-0000-000000000001'::UUID, 'jean.kamga@bollore.cm', 'Jean-Pierre Kamga', '+237 677 10 00 01', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000001'::UUID),
            ('10000000-0000-0000-0000-000000000002'::UUID, 'marie.ngo@bollore.cm', 'Marie-Thérèse Ngo Bassa', '+237 677 10 00 02', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000001'::UUID),
            ('10000000-0000-0000-0000-000000000003'::UUID, 'paul.essomba@bollore.cm', 'Paul Essomba Nkolo', '+237 677 10 00 03', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000001'::UUID),
            ('10000000-0000-0000-0000-000000000004'::UUID, 'florence.atangana@bollore.cm', 'Florence Atangana Messi', '+237 677 10 00 04', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000002'::UUID),
            ('10000000-0000-0000-0000-000000000005'::UUID, 'samuel.mbarga@bollore.cm', 'Samuel Mbarga Owona', '+237 677 10 00 05', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000002'::UUID),
            ('10000000-0000-0000-0000-000000000006'::UUID, 'celine.fotso@bollore.cm', 'Céline Fotso Kuaté', '+237 677 10 00 06', 'a0000000-0000-0000-0000-000000000001'::UUID, 'b0000000-0000-0000-0000-000000000002'::UUID),
            ('10000000-0000-0000-0000-000000000007'::UUID, 'armand.tchinda@orange.cm', 'Armand Tchinda Fokou', '+237 699 20 00 01', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000003'::UUID),
            ('10000000-0000-0000-0000-000000000008'::UUID, 'berthe.njoya@orange.cm', 'Berthe Njoya Mfopou', '+237 699 20 00 02', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000003'::UUID),
            ('10000000-0000-0000-0000-000000000009'::UUID, 'didier.onana@orange.cm', 'Didier Onana Mvogo', '+237 699 20 00 03', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000003'::UUID),
            ('10000000-0000-0000-0000-000000000010'::UUID, 'estelle.mbia@orange.cm', 'Estelle Mbia Abena', '+237 699 20 00 04', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000003'::UUID),
            ('10000000-0000-0000-0000-000000000011'::UUID, 'gaston.njike@orange.cm', 'Gaston Njike Pokam', '+237 699 20 00 05', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000004'::UUID),
            ('10000000-0000-0000-0000-000000000012'::UUID, 'helene.tabi@orange.cm', 'Hélène Tabi Mengue', '+237 699 20 00 06', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000004'::UUID),
            ('10000000-0000-0000-0000-000000000013'::UUID, 'ibrahim.moussa@orange.cm', 'Ibrahim Moussa Adamou', '+237 699 20 00 07', 'a0000000-0000-0000-0000-000000000002'::UUID, 'b0000000-0000-0000-0000-000000000004'::UUID),
            ('10000000-0000-0000-0000-000000000014'::UUID, 'jules.ngando@socgen.cm', 'Jules Ngando Ekambi', '+237 655 30 00 01', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000005'::UUID),
            ('10000000-0000-0000-0000-000000000015'::UUID, 'karine.ewane@socgen.cm', 'Karine Ewane Ndongo', '+237 655 30 00 02', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000005'::UUID),
            ('10000000-0000-0000-0000-000000000016'::UUID, 'leopold.nkeng@socgen.cm', 'Léopold Nkeng Assoumou', '+237 655 30 00 03', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000005'::UUID),
            ('10000000-0000-0000-0000-000000000017'::UUID, 'monique.bell@socgen.cm', 'Monique Bell Lobe', '+237 655 30 00 04', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000005'::UUID),
            ('10000000-0000-0000-0000-000000000018'::UUID, 'narcisse.mekongo@socgen.cm', 'Narcisse Mekongo Abolo', '+237 655 30 00 05', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000006'::UUID),
            ('10000000-0000-0000-0000-000000000019'::UUID, 'olivia.douala@socgen.cm', 'Olivia Douala Manga', '+237 655 30 00 06', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000006'::UUID),
            ('10000000-0000-0000-0000-000000000020'::UUID, 'roger.biya@socgen.cm', 'Roger Biya Mvondo', '+237 655 30 00 07', 'a0000000-0000-0000-0000-000000000003'::UUID, 'b0000000-0000-0000-0000-000000000006'::UUID)
        ) AS t(id, email, full_name, phone, company_id, site_id)
    LOOP
        -- Insert into auth.users (Supabase manages this table)
        BEGIN
            INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, role)
            VALUES (
                emp.id,
                emp.email,
                crypt('password123', gen_salt('bf')),
                now(),
                now(),
                now(),
                '{"provider":"email","providers":["email"]}'::JSONB,
                json_build_object('full_name', emp.full_name)::JSONB,
                'authenticated',
                'authenticated'
            )
            ON CONFLICT (id) DO NOTHING;
        EXCEPTION WHEN OTHERS THEN
            -- If auth.users insert fails (e.g., missing columns in different Supabase versions), continue
            RAISE NOTICE 'Could not insert into auth.users for %: %. Inserting profile directly.', emp.email, SQLERRM;
        END;

        -- Insert into profiles
        BEGIN
            INSERT INTO profiles (id, email, full_name, phone, company_id, site_id, is_active)
            VALUES (emp.id, emp.email, emp.full_name, emp.phone, emp.company_id, emp.site_id, true)
            ON CONFLICT (id) DO NOTHING;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not insert profile for %: %', emp.email, SQLERRM;
        END;
    END LOOP;
END $$;

-- -------------------------------------------------------
-- 8.16 User Roles (assign roles to some employees)
-- -------------------------------------------------------
DO $$
BEGIN
    -- Mily's admin (superadmin)
    INSERT INTO user_roles (user_id, role) VALUES
        ('10000000-0000-0000-0000-000000000001', 'superadmin')
    ON CONFLICT (user_id, role) DO NOTHING;

    -- Company admins
    INSERT INTO user_roles (user_id, role) VALUES
        ('10000000-0000-0000-0000-000000000002', 'company_admin'),  -- Bolloré admin
        ('10000000-0000-0000-0000-000000000007', 'company_admin'),  -- Orange admin
        ('10000000-0000-0000-0000-000000000014', 'company_admin')   -- SG admin
    ON CONFLICT (user_id, role) DO NOTHING;

    -- Employees
    INSERT INTO user_roles (user_id, role) VALUES
        ('10000000-0000-0000-0000-000000000003', 'employee'),
        ('10000000-0000-0000-0000-000000000004', 'employee'),
        ('10000000-0000-0000-0000-000000000005', 'employee'),
        ('10000000-0000-0000-0000-000000000006', 'employee'),
        ('10000000-0000-0000-0000-000000000008', 'employee'),
        ('10000000-0000-0000-0000-000000000009', 'employee'),
        ('10000000-0000-0000-0000-000000000010', 'employee'),
        ('10000000-0000-0000-0000-000000000011', 'employee'),
        ('10000000-0000-0000-0000-000000000012', 'employee'),
        ('10000000-0000-0000-0000-000000000013', 'employee'),
        ('10000000-0000-0000-0000-000000000015', 'employee'),
        ('10000000-0000-0000-0000-000000000016', 'employee'),
        ('10000000-0000-0000-0000-000000000017', 'employee'),
        ('10000000-0000-0000-0000-000000000018', 'employee'),
        ('10000000-0000-0000-0000-000000000019', 'employee'),
        ('10000000-0000-0000-0000-000000000020', 'employee')
    ON CONFLICT (user_id, role) DO NOTHING;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not insert user roles: %', SQLERRM;
END $$;

-- -------------------------------------------------------
-- 8.17 Sample Orders
-- -------------------------------------------------------
DO $$
BEGIN
    -- Monday orders
    INSERT INTO orders (user_id, menu_id, order_date, status, total_amount, notes) VALUES
        ('10000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', '2026-02-23', 'delivered', 3000.00, 'Ndolé + Jus Foléré'),
        ('10000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', '2026-02-23', 'delivered', 2500.00, 'Ndolé sans piment'),
        ('10000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000001', '2026-02-23', 'delivered', 4000.00, 'Ndolé + Riz sauté + Jus Foléré'),
        ('10000000-0000-0000-0000-000000000015', 'c0000000-0000-0000-0000-000000000001', '2026-02-23', 'delivered', 2500.00, NULL),
    -- Tuesday orders
        ('10000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000002', '2026-02-24', 'delivered', 3500.00, 'Poulet DG'),
        ('10000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000002', '2026-02-24', 'delivered', 5000.00, 'Poulet DG + Soya + Jus'),
        ('10000000-0000-0000-0000-000000000016', 'c0000000-0000-0000-0000-000000000002', '2026-02-24', 'delivered', 3500.00, NULL),
    -- Wednesday orders
        ('10000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000003', '2026-02-25', 'delivered', 3300.00, 'Poisson braisé + Miondo'),
        ('10000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000003', '2026-02-25', 'delivered', 4000.00, 'Poisson braisé + Koki + Miondo'),
        ('10000000-0000-0000-0000-000000000018', 'c0000000-0000-0000-0000-000000000003', '2026-02-25', 'delivered', 3000.00, NULL),
    -- Thursday orders (today)
        ('10000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000004', '2026-02-26', 'confirmed', 2000.00, 'Eru'),
        ('10000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000004', '2026-02-26', 'in_production', 3500.00, 'Eru + Sauce gombo + Riz'),
        ('10000000-0000-0000-0000-000000000011', 'c0000000-0000-0000-0000-000000000004', '2026-02-26', 'pending', 2000.00, 'Sauce gombo + Riz sauté'),
        ('10000000-0000-0000-0000-000000000019', 'c0000000-0000-0000-0000-000000000004', '2026-02-26', 'pending', 3500.00, 'Eru + Riz sauté + Gombo'),
    -- Friday orders (pre-orders)
        ('10000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', '2026-02-27', 'pending', 3000.00, 'Mbongo Tchobi'),
        ('10000000-0000-0000-0000-000000000012', 'c0000000-0000-0000-0000-000000000005', '2026-02-27', 'pending', 5500.00, 'Mbongo + Kondré + Jus')
    ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not insert sample orders: %', SQLERRM;
END $$;

-- -------------------------------------------------------
-- 8.18 Sample Production Batches
-- -------------------------------------------------------
INSERT INTO production_batches (menu_id, planned_quantity, produced_quantity, production_date, started_at, completed_at) VALUES
    ('c0000000-0000-0000-0000-000000000001', 80, 78, '2026-02-23', '2026-02-23 06:00:00+01', '2026-02-23 10:30:00+01'),
    ('c0000000-0000-0000-0000-000000000002', 75, 72, '2026-02-24', '2026-02-24 06:00:00+01', '2026-02-24 10:45:00+01'),
    ('c0000000-0000-0000-0000-000000000003', 70, 70, '2026-02-25', '2026-02-25 06:00:00+01', '2026-02-25 10:15:00+01'),
    ('c0000000-0000-0000-0000-000000000004', 75, 0, '2026-02-26', '2026-02-26 06:00:00+01', NULL),
    ('c0000000-0000-0000-0000-000000000005', 70, 0, '2026-02-27', NULL, NULL)
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.19 Sample Stock Movements
-- -------------------------------------------------------
INSERT INTO stock_movements (ingredient_id, movement_type, quantity, reason) VALUES
    ('e0000000-0000-0000-0000-000000000001', 'entry', 30.0, 'Livraison Marché Central - Feuilles de ndolé'),
    ('e0000000-0000-0000-0000-000000000005', 'entry', 40.0, 'Livraison AgroCam - Poulets'),
    ('e0000000-0000-0000-0000-000000000006', 'entry', 20.0, 'Livraison Pêcheries du Wouri - Bar'),
    ('e0000000-0000-0000-0000-000000000013', 'entry', 100.0, 'Livraison AgroCam - Riz long grain'),
    ('e0000000-0000-0000-0000-000000000001', 'exit', 15.0, 'Production Ndolé - Lundi'),
    ('e0000000-0000-0000-0000-000000000005', 'exit', 20.0, 'Production Poulet DG - Mardi'),
    ('e0000000-0000-0000-0000-000000000006', 'exit', 12.0, 'Production Poisson braisé - Mercredi'),
    ('e0000000-0000-0000-0000-000000000011', 'waste', 2.0, 'Tomates abîmées - perte'),
    ('e0000000-0000-0000-0000-000000000004', 'adjustment', -5.0, 'Correction inventaire plantain')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.20 Sample Purchase Order
-- -------------------------------------------------------
DO $$
DECLARE
    po_id UUID;
BEGIN
    INSERT INTO purchase_orders (id, supplier_id, status, total_amount, ordered_at)
    VALUES (gen_random_uuid(), 'f0000000-0000-0000-0000-000000000001', 'delivered', 45000.00, '2026-02-20 09:00:00+01')
    RETURNING id INTO po_id;

    INSERT INTO purchase_order_items (purchase_order_id, ingredient_id, quantity, unit_price) VALUES
        (po_id, 'e0000000-0000-0000-0000-000000000001', 20.0, 1400.00),
        (po_id, 'e0000000-0000-0000-0000-000000000004', 30.0, 450.00),
        (po_id, 'e0000000-0000-0000-0000-000000000010', 10.0, 550.00);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not insert purchase order: %', SQLERRM;
END $$;

-- -------------------------------------------------------
-- 8.21 Sample Physical Tickets
-- -------------------------------------------------------
INSERT INTO physical_tickets (company_id, ticket_number, value, status) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'BTL-TK-2026-0001', 3500.00, 'active'),
    ('a0000000-0000-0000-0000-000000000001', 'BTL-TK-2026-0002', 3500.00, 'active'),
    ('a0000000-0000-0000-0000-000000000001', 'BTL-TK-2026-0003', 3500.00, 'used'),
    ('a0000000-0000-0000-0000-000000000002', 'ORC-TK-2026-0001', 4000.00, 'active'),
    ('a0000000-0000-0000-0000-000000000002', 'ORC-TK-2026-0002', 4000.00, 'active'),
    ('a0000000-0000-0000-0000-000000000003', 'SGC-TK-2026-0001', 5000.00, 'active'),
    ('a0000000-0000-0000-0000-000000000003', 'SGC-TK-2026-0002', 5000.00, 'active')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------
-- 8.22 Sample Invoice
-- -------------------------------------------------------
DO $$
DECLARE
    inv_id UUID;
    pay_id UUID;
BEGIN
    INSERT INTO invoices (id, company_id, invoice_number, period_start, period_end, subtotal, tax_amount, total_amount, status, due_date, issued_at)
    VALUES (
        gen_random_uuid(),
        'a0000000-0000-0000-0000-000000000001',
        'MILYS-INV-2026-0001',
        '2026-02-01',
        '2026-02-28',
        840000.00,
        161700.00,
        1001700.00,
        'pending',
        '2026-03-15',
        now()
    )
    RETURNING id INTO inv_id;

    INSERT INTO invoice_items (invoice_id, description, quantity, unit_price, amount) VALUES
        (inv_id, 'Forfait déjeuner - Février 2026 (6 employés x 20 jours)', 120, 3500.00, 420000.00),
        (inv_id, 'Forfait déjeuner - Février 2026 (6 employés x 20 jours - Site Yaoundé)', 120, 3500.00, 420000.00);

    INSERT INTO payments (id, invoice_id, amount, payment_method, reference, paid_at)
    VALUES (gen_random_uuid(), inv_id, 500000.00, 'bank_transfer', 'VIR-BTL-2026-02-001', '2026-02-25 10:00:00+01')
    RETURNING id INTO pay_id;

    INSERT INTO invoice_payments (invoice_id, payment_id, amount_applied)
    VALUES (inv_id, pay_id, 500000.00);

    -- Update invoice status to partial
    UPDATE invoices SET status = 'partial' WHERE id = inv_id;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not insert sample invoice: %', SQLERRM;
END $$;

-- -------------------------------------------------------
-- 8.23 Sample Notifications
-- -------------------------------------------------------
DO $$
BEGIN
    INSERT INTO notifications (user_id, title, message, type, is_read, action_url) VALUES
        ('10000000-0000-0000-0000-000000000001', 'Nouvelle commande reçue', 'Paul Essomba a passé une commande pour le déjeuner de jeudi.', 'order', false, '/orders'),
        ('10000000-0000-0000-0000-000000000003', 'Votre commande est confirmée', 'Votre commande de Ndolé pour lundi a été confirmée.', 'order', true, '/my-orders'),
        ('10000000-0000-0000-0000-000000000007', 'Facture en attente', 'La facture MILYS-INV-2026-0001 est en attente de règlement.', 'invoice', false, '/invoices'),
        ('10000000-0000-0000-0000-000000000001', 'Stock bas - Alerte', 'Le stock de piment est en dessous du seuil minimum (3 kg restants).', 'alert', false, '/stock'),
        ('10000000-0000-0000-0000-000000000002', 'Menu de la semaine publié', 'Le menu de la semaine 9 (23-27 février) est maintenant disponible.', 'menu', false, '/menus')
    ON CONFLICT DO NOTHING;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Could not insert sample notifications: %', SQLERRM;
END $$;

-- ============================================================================
-- SCHEMA COMPLETE
-- MILY'S Restauration Management - Ready for Supabase
-- ============================================================================

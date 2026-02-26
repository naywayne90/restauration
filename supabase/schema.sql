-- ============================================================================
-- MILY'S - Schéma complet de la base de données
-- Application de restauration d'entreprise
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE user_role_type AS ENUM (
  'superadmin', 'milys_admin', 'milys_kitchen', 'milys_logistics',
  'milys_cashier', 'company_admin', 'company_cashier',
  'third_party_cashier', 'employee'
);

CREATE TYPE order_status_type AS ENUM (
  'pending', 'confirmed', 'in_production', 'ready',
  'delivering', 'delivered', 'cancelled'
);

CREATE TYPE delivery_status_type AS ENUM (
  'pending', 'in_transit', 'delivered', 'failed'
);

CREATE TYPE payment_status_type AS ENUM (
  'pending', 'partial', 'paid', 'overdue', 'cancelled'
);

CREATE TYPE payment_method_type AS ENUM (
  'cash', 'mobile_money', 'bank_transfer', 'card', 'ticket'
);

CREATE TYPE ticket_status_type AS ENUM (
  'active', 'used', 'expired', 'cancelled'
);

CREATE TYPE stock_movement_type AS ENUM (
  'entry', 'exit', 'adjustment', 'waste'
);

CREATE TYPE contract_type AS ENUM (
  'forfait', 'a_la_carte', 'mixed'
);

CREATE TYPE meal_type AS ENUM (
  'petit_dejeuner', 'dejeuner', 'diner', 'collation'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- 1. Companies (avant profiles car profiles référence companies)
CREATE TABLE companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  code TEXT NOT NULL UNIQUE,
  logo_url TEXT,
  address TEXT,
  city TEXT,
  contact_name TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Company Sites
CREATE TABLE company_sites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT,
  city TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Profiles
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  site_id UUID REFERENCES company_sites(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. User Roles
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role user_role_type NOT NULL,
  granted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  granted_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, role)
);

-- 5. Company Contracts
CREATE TABLE company_contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  contract_type contract_type NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  daily_budget_per_employee NUMERIC(10,2),
  meal_types_included TEXT[] DEFAULT ARRAY['dejeuner'],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Dishes
CREATE TABLE dishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT,
  image_url TEXT,
  base_price NUMERIC(10,2) NOT NULL,
  is_available BOOLEAN DEFAULT true,
  preparation_time_min INTEGER,
  calories INTEGER,
  is_vegetarian BOOLEAN DEFAULT false,
  is_vegan BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 7. Ingredients
CREATE TABLE ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  unit TEXT NOT NULL,
  unit_price NUMERIC(10,2) DEFAULT 0,
  stock_quantity NUMERIC(10,2) DEFAULT 0,
  min_stock_threshold NUMERIC(10,2) DEFAULT 0,
  category TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 8. Dish Ingredients
CREATE TABLE dish_ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  quantity_needed NUMERIC(10,3) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 9. Dish Allergens
CREATE TABLE dish_allergens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
  allergen_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 10. Dish Ratings
CREATE TABLE dish_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 11. Suppliers
CREATE TABLE suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  contact_name TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 12. Supplier Ingredients
CREATE TABLE supplier_ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  supply_price NUMERIC(10,2) NOT NULL,
  delivery_delay_days INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 13. Stock Movements
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  movement_type stock_movement_type NOT NULL,
  quantity NUMERIC(10,2) NOT NULL,
  reason TEXT,
  performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 14. Purchase Orders
CREATE TABLE purchase_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'draft',
  total_amount NUMERIC(12,2) DEFAULT 0,
  ordered_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  ordered_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 15. Purchase Order Items
CREATE TABLE purchase_order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_order_id UUID NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
  ingredient_id UUID NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  quantity NUMERIC(10,2) NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 16. Menus
CREATE TABLE menus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  date DATE NOT NULL,
  meal_type meal_type NOT NULL DEFAULT 'dejeuner',
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 17. Menu Items
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
  dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
  is_main_course BOOLEAN DEFAULT false,
  max_quantity INTEGER,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 18. Weekly Plans
CREATE TABLE weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_start_date DATE NOT NULL,
  week_end_date DATE NOT NULL,
  company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
  is_validated BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 19. Weekly Plan Items
CREATE TABLE weekly_plan_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_plan_id UUID NOT NULL REFERENCES weekly_plans(id) ON DELETE CASCADE,
  menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 20. QR Codes
CREATE TABLE qr_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  is_single_use BOOLEAN DEFAULT false,
  is_used BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 21. Orders
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  menu_id UUID REFERENCES menus(id) ON DELETE SET NULL,
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status order_status_type DEFAULT 'pending',
  total_amount NUMERIC(10,2) DEFAULT 0,
  notes TEXT,
  qr_code_id UUID REFERENCES qr_codes(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 22. QR Scans
CREATE TABLE qr_scans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  qr_code_id UUID NOT NULL REFERENCES qr_codes(id) ON DELETE CASCADE,
  scanned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  scanned_at TIMESTAMPTZ DEFAULT now(),
  location TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 23. Physical Tickets
CREATE TABLE physical_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  ticket_number TEXT NOT NULL UNIQUE,
  value NUMERIC(10,2) NOT NULL,
  status ticket_status_type DEFAULT 'active',
  used_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 24. Production Batches
CREATE TABLE production_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  menu_id UUID NOT NULL REFERENCES menus(id) ON DELETE CASCADE,
  planned_quantity INTEGER NOT NULL,
  produced_quantity INTEGER DEFAULT 0,
  production_date DATE NOT NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  supervised_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 25. Drivers
CREATE TABLE drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  vehicle_info TEXT,
  license_plate TEXT,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 26. Deliveries
CREATE TABLE deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  driver_id UUID REFERENCES drivers(id) ON DELETE SET NULL,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  site_id UUID REFERENCES company_sites(id) ON DELETE SET NULL,
  status delivery_status_type DEFAULT 'pending',
  scheduled_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  signature_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 27. Delivery Items
CREATE TABLE delivery_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id UUID NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
  dish_id UUID NOT NULL REFERENCES dishes(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  temperature_check NUMERIC(4,1),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 28. Formulas
CREATE TABLE formulas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  dishes_included INTEGER NOT NULL DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 29. Invoices
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  invoice_number TEXT NOT NULL UNIQUE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  subtotal NUMERIC(12,2) DEFAULT 0,
  tax_amount NUMERIC(12,2) DEFAULT 0,
  total_amount NUMERIC(12,2) DEFAULT 0,
  status payment_status_type DEFAULT 'pending',
  due_date DATE,
  issued_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 30. Invoice Items
CREATE TABLE invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  unit_price NUMERIC(10,2) NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 31. Invoice Employee Details
CREATE TABLE invoice_employee_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  meals_count INTEGER NOT NULL DEFAULT 0,
  total_amount NUMERIC(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 32. Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  payment_method payment_method_type NOT NULL,
  reference TEXT,
  paid_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 33. Invoice Payments
CREATE TABLE invoice_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  amount_applied NUMERIC(12,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 34. Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT,
  type TEXT,
  is_read BOOLEAN DEFAULT false,
  action_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 35. Audit Logs
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  table_name TEXT NOT NULL,
  record_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 36. App Config
CREATE TABLE app_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profiles
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_company_id ON profiles(company_id);
CREATE INDEX idx_profiles_site_id ON profiles(site_id);

-- User Roles
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);

-- Companies
CREATE INDEX idx_companies_code ON companies(code);
CREATE INDEX idx_companies_is_active ON companies(is_active);

-- Company Sites
CREATE INDEX idx_company_sites_company_id ON company_sites(company_id);

-- Company Contracts
CREATE INDEX idx_company_contracts_company_id ON company_contracts(company_id);
CREATE INDEX idx_company_contracts_is_active ON company_contracts(is_active);

-- Dishes
CREATE INDEX idx_dishes_category ON dishes(category);
CREATE INDEX idx_dishes_is_available ON dishes(is_available);

-- Ingredients
CREATE INDEX idx_ingredients_category ON ingredients(category);

-- Dish Ingredients
CREATE INDEX idx_dish_ingredients_dish_id ON dish_ingredients(dish_id);
CREATE INDEX idx_dish_ingredients_ingredient_id ON dish_ingredients(ingredient_id);

-- Dish Allergens
CREATE INDEX idx_dish_allergens_dish_id ON dish_allergens(dish_id);

-- Dish Ratings
CREATE INDEX idx_dish_ratings_dish_id ON dish_ratings(dish_id);
CREATE INDEX idx_dish_ratings_user_id ON dish_ratings(user_id);

-- Suppliers
CREATE INDEX idx_suppliers_is_active ON suppliers(is_active);

-- Supplier Ingredients
CREATE INDEX idx_supplier_ingredients_supplier_id ON supplier_ingredients(supplier_id);
CREATE INDEX idx_supplier_ingredients_ingredient_id ON supplier_ingredients(ingredient_id);

-- Stock Movements
CREATE INDEX idx_stock_movements_ingredient_id ON stock_movements(ingredient_id);
CREATE INDEX idx_stock_movements_type ON stock_movements(movement_type);
CREATE INDEX idx_stock_movements_created_at ON stock_movements(created_at);

-- Purchase Orders
CREATE INDEX idx_purchase_orders_supplier_id ON purchase_orders(supplier_id);
CREATE INDEX idx_purchase_orders_status ON purchase_orders(status);
CREATE INDEX idx_purchase_orders_ordered_at ON purchase_orders(ordered_at);

-- Purchase Order Items
CREATE INDEX idx_purchase_order_items_order_id ON purchase_order_items(purchase_order_id);
CREATE INDEX idx_purchase_order_items_ingredient_id ON purchase_order_items(ingredient_id);

-- Menus
CREATE INDEX idx_menus_date ON menus(date);
CREATE INDEX idx_menus_meal_type ON menus(meal_type);
CREATE INDEX idx_menus_is_published ON menus(is_published);

-- Menu Items
CREATE INDEX idx_menu_items_menu_id ON menu_items(menu_id);
CREATE INDEX idx_menu_items_dish_id ON menu_items(dish_id);

-- Weekly Plans
CREATE INDEX idx_weekly_plans_dates ON weekly_plans(week_start_date, week_end_date);
CREATE INDEX idx_weekly_plans_company_id ON weekly_plans(company_id);

-- Weekly Plan Items
CREATE INDEX idx_weekly_plan_items_plan_id ON weekly_plan_items(weekly_plan_id);
CREATE INDEX idx_weekly_plan_items_menu_id ON weekly_plan_items(menu_id);

-- QR Codes
CREATE INDEX idx_qr_codes_user_id ON qr_codes(user_id);
CREATE INDEX idx_qr_codes_code ON qr_codes(code);

-- Orders
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_menu_id ON orders(menu_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_date ON orders(order_date);

-- QR Scans
CREATE INDEX idx_qr_scans_qr_code_id ON qr_scans(qr_code_id);
CREATE INDEX idx_qr_scans_scanned_at ON qr_scans(scanned_at);

-- Physical Tickets
CREATE INDEX idx_physical_tickets_company_id ON physical_tickets(company_id);
CREATE INDEX idx_physical_tickets_status ON physical_tickets(status);

-- Production Batches
CREATE INDEX idx_production_batches_menu_id ON production_batches(menu_id);
CREATE INDEX idx_production_batches_date ON production_batches(production_date);

-- Drivers
CREATE INDEX idx_drivers_user_id ON drivers(user_id);
CREATE INDEX idx_drivers_is_available ON drivers(is_available);

-- Deliveries
CREATE INDEX idx_deliveries_order_id ON deliveries(order_id);
CREATE INDEX idx_deliveries_driver_id ON deliveries(driver_id);
CREATE INDEX idx_deliveries_company_id ON deliveries(company_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
CREATE INDEX idx_deliveries_scheduled_at ON deliveries(scheduled_at);

-- Delivery Items
CREATE INDEX idx_delivery_items_delivery_id ON delivery_items(delivery_id);
CREATE INDEX idx_delivery_items_dish_id ON delivery_items(dish_id);

-- Invoices
CREATE INDEX idx_invoices_company_id ON invoices(company_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);

-- Invoice Items
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id);

-- Invoice Employee Details
CREATE INDEX idx_invoice_employee_details_invoice_id ON invoice_employee_details(invoice_id);
CREATE INDEX idx_invoice_employee_details_employee_id ON invoice_employee_details(employee_id);

-- Payments
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);

-- Invoice Payments
CREATE INDEX idx_invoice_payments_invoice_id ON invoice_payments(invoice_id);
CREATE INDEX idx_invoice_payments_payment_id ON invoice_payments(payment_id);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Audit Logs
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_name ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- ============================================================================
-- TRIGGERS: updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT unnest(ARRAY[
      'companies', 'company_sites', 'profiles', 'user_roles',
      'company_contracts', 'dishes', 'ingredients', 'dish_ingredients',
      'dish_allergens', 'dish_ratings', 'suppliers', 'supplier_ingredients',
      'stock_movements', 'purchase_orders', 'purchase_order_items',
      'menus', 'menu_items', 'weekly_plans', 'weekly_plan_items',
      'qr_codes', 'orders', 'qr_scans', 'physical_tickets',
      'production_batches', 'drivers', 'deliveries', 'delivery_items',
      'formulas', 'invoices', 'invoice_items', 'invoice_employee_details',
      'payments', 'invoice_payments', 'notifications', 'audit_logs', 'app_config'
    ])
  LOOP
    EXECUTE format(
      'CREATE TRIGGER set_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      t
    );
  END LOOP;
END;
$$;

-- ============================================================================
-- TRIGGERS: Audit Log
-- ============================================================================

CREATE OR REPLACE FUNCTION log_audit_event()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, OLD.id, to_jsonb(OLD));
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, old_data, new_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    INSERT INTO audit_logs (user_id, action, table_name, record_id, new_data)
    VALUES (auth.uid(), TG_OP, TG_TABLE_NAME, NEW.id, to_jsonb(NEW));
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER audit_orders AFTER INSERT OR UPDATE OR DELETE ON orders
  FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_invoices AFTER INSERT OR UPDATE OR DELETE ON invoices
  FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION log_audit_event();

CREATE TRIGGER audit_deliveries AFTER INSERT OR UPDATE OR DELETE ON deliveries
  FOR EACH ROW EXECUTE FUNCTION log_audit_event();

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Helper function to check admin roles
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND role IN ('superadmin', 'milys_admin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check any specific role
CREATE OR REPLACE FUNCTION has_role(required_role user_role_type)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND role = required_role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS on all tables
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE dish_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE dish_allergens ENABLE ROW LEVEL SECURITY;
ALTER TABLE dish_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE physical_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE production_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE formulas ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_employee_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- ========================
-- PROFILES POLICIES
-- ========================
CREATE POLICY "profiles_select_own" ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "profiles_select_admin" ON profiles FOR SELECT
  USING (is_admin());

CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "profiles_all_admin" ON profiles FOR ALL
  USING (is_admin());

-- ========================
-- ORDERS POLICIES
-- ========================
CREATE POLICY "orders_select_own" ON orders FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "orders_insert_own" ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "orders_select_admin" ON orders FOR SELECT
  USING (is_admin());

CREATE POLICY "orders_all_admin" ON orders FOR ALL
  USING (is_admin());

-- ========================
-- COMPANIES POLICIES
-- ========================
CREATE POLICY "companies_select_auth" ON companies FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "companies_manage_company_admin" ON companies FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles ur
      JOIN profiles p ON p.id = ur.user_id
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'company_admin'
      AND p.company_id = companies.id
    )
  );

CREATE POLICY "companies_all_admin" ON companies FOR ALL
  USING (is_admin());

-- ========================
-- GENERIC READ POLICIES (authenticated can read, admin can manage)
-- ========================
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT unnest(ARRAY[
      'company_sites', 'user_roles', 'company_contracts',
      'dishes', 'ingredients', 'dish_ingredients', 'dish_allergens',
      'dish_ratings', 'suppliers', 'supplier_ingredients',
      'stock_movements', 'purchase_orders', 'purchase_order_items',
      'menus', 'menu_items', 'weekly_plans', 'weekly_plan_items',
      'qr_codes', 'qr_scans', 'physical_tickets',
      'production_batches', 'drivers', 'deliveries', 'delivery_items',
      'formulas', 'invoices', 'invoice_items', 'invoice_employee_details',
      'payments', 'invoice_payments', 'app_config'
    ])
  LOOP
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR SELECT TO authenticated USING (true)',
      t || '_select_auth', t
    );
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR INSERT TO authenticated WITH CHECK (is_admin())',
      t || '_insert_admin', t
    );
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR UPDATE TO authenticated USING (is_admin())',
      t || '_update_admin', t
    );
    EXECUTE format(
      'CREATE POLICY %I ON %I FOR DELETE TO authenticated USING (is_admin())',
      t || '_delete_admin', t
    );
  END LOOP;
END;
$$;

-- Notifications: users see their own
CREATE POLICY "notifications_select_own" ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notifications_update_own" ON notifications FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "notifications_all_admin" ON notifications FOR ALL
  USING (is_admin());

-- Audit logs: only admins
CREATE POLICY "audit_logs_select_admin" ON audit_logs FOR SELECT
  USING (is_admin());

CREATE POLICY "audit_logs_insert" ON audit_logs FOR INSERT
  TO authenticated WITH CHECK (true);

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Companies
INSERT INTO companies (id, name, code, address, city, contact_name, contact_email, contact_phone) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Bolloré Transport & Logistics', 'BTL', 'Rue de la Gare, Bonanjo', 'Douala', 'Jean-Pierre Kamga', 'jp.kamga@bollore.cm', '+237 699 001 001'),
  ('a0000000-0000-0000-0000-000000000002', 'Orange Cameroun', 'ORC', 'Boulevard de la Liberté', 'Douala', 'Marie-Claire Ngo', 'mc.ngo@orange.cm', '+237 699 002 002'),
  ('a0000000-0000-0000-0000-000000000003', 'Société Générale Cameroun', 'SGC', 'Rue Joss, Bonanjo', 'Douala', 'Paul Essomba', 'p.essomba@socgen.cm', '+237 699 003 003');

-- Company Sites
INSERT INTO company_sites (id, company_id, name, address, city) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Siège Bonanjo', 'Rue de la Gare', 'Douala'),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Entrepôt Bassa', 'Zone Industrielle Bassa', 'Douala'),
  ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'Siège Akwa', 'Boulevard de la Liberté', 'Douala'),
  ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000002', 'Agence Bonapriso', 'Rue Franqueville', 'Douala'),
  ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000003', 'Agence Bonanjo', 'Rue Joss', 'Douala'),
  ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000003', 'Agence Akwa', 'Rue Castelnau', 'Douala');

-- Company Contracts
INSERT INTO company_contracts (company_id, contract_type, start_date, end_date, daily_budget_per_employee, meal_types_included) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'forfait', '2026-01-01', '2026-12-31', 3500, ARRAY['dejeuner']),
  ('a0000000-0000-0000-0000-000000000002', 'mixed', '2026-01-01', '2026-12-31', 4000, ARRAY['dejeuner', 'collation']),
  ('a0000000-0000-0000-0000-000000000003', 'a_la_carte', '2026-01-01', '2026-06-30', 5000, ARRAY['dejeuner']);

-- Dishes (Cameroonian cuisine in FCFA)
INSERT INTO dishes (id, name, description, category, base_price, preparation_time_min, calories, is_vegetarian) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'Ndolé', 'Feuilles de ndolé aux crevettes et viande, accompagnées de plantain', 'Plat principal', 2500, 60, 650, false),
  ('d0000000-0000-0000-0000-000000000002', 'Eru', 'Eru aux waterleaf, garni de viande et poisson fumé', 'Plat principal', 2800, 45, 580, false),
  ('d0000000-0000-0000-0000-000000000003', 'Poulet DG', 'Poulet sauté aux légumes et plantain mûr frit', 'Plat principal', 3000, 50, 720, false),
  ('d0000000-0000-0000-0000-000000000004', 'Poisson braisé', 'Bar entier braisé aux épices camerounaises', 'Plat principal', 3500, 40, 480, false),
  ('d0000000-0000-0000-0000-000000000005', 'Beignets haricots', 'Beignets de haricots niébé croustillants avec bouillie', 'Petit-déjeuner', 500, 20, 350, true),
  ('d0000000-0000-0000-0000-000000000006', 'Koki', 'Gâteau de haricots cornilles cuit à la vapeur dans des feuilles de bananier', 'Accompagnement', 1000, 90, 320, true),
  ('d0000000-0000-0000-0000-000000000007', 'Mbongo tchobi', 'Poisson en sauce noire aux épices', 'Plat principal', 3200, 55, 510, false),
  ('d0000000-0000-0000-0000-000000000008', 'Kondre', 'Ragoût de plantain vert à la viande de chèvre', 'Plat principal', 2800, 70, 620, false),
  ('d0000000-0000-0000-0000-000000000009', 'Achu', 'Cocoasse pilée avec sauce jaune', 'Plat principal', 2000, 60, 550, false),
  ('d0000000-0000-0000-0000-000000000010', 'Riz sauce arachide', 'Riz blanc accompagné de sauce d''arachide au poulet', 'Plat principal', 2000, 35, 600, false),
  ('d0000000-0000-0000-0000-000000000011', 'Sanga', 'Maïs et feuilles de manioc pilés ensemble', 'Plat principal', 1800, 50, 480, true),
  ('d0000000-0000-0000-0000-000000000012', 'Okok', 'Feuilles de Gnetum africanum à la pâte d''arachide', 'Plat principal', 2200, 45, 400, false),
  ('d0000000-0000-0000-0000-000000000013', 'Salade composée', 'Salade mixte avec avocat, tomate et vinaigrette', 'Entrée', 800, 10, 180, true),
  ('d0000000-0000-0000-0000-000000000014', 'Jus de gingembre', 'Jus de gingembre frais au citron et miel', 'Boisson', 500, 5, 90, true),
  ('d0000000-0000-0000-0000-000000000015', 'Fruits de saison', 'Assortiment de mangue, papaye, ananas et pastèque', 'Dessert', 600, 5, 120, true);

-- Ingredients
INSERT INTO ingredients (id, name, unit, unit_price, stock_quantity, min_stock_threshold, category) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'Feuilles de ndolé', 'kg', 1500, 50, 10, 'Légumes'),
  ('e0000000-0000-0000-0000-000000000002', 'Crevettes', 'kg', 5000, 20, 5, 'Fruits de mer'),
  ('e0000000-0000-0000-0000-000000000003', 'Plantain mûr', 'régime', 2000, 30, 8, 'Féculents'),
  ('e0000000-0000-0000-0000-000000000004', 'Poulet entier', 'unité', 3500, 40, 10, 'Viandes'),
  ('e0000000-0000-0000-0000-000000000005', 'Bar (poisson)', 'kg', 4000, 25, 5, 'Poissons'),
  ('e0000000-0000-0000-0000-000000000006', 'Huile de palme', 'litre', 1200, 60, 15, 'Huiles'),
  ('e0000000-0000-0000-0000-000000000007', 'Riz', 'kg', 600, 100, 25, 'Féculents'),
  ('e0000000-0000-0000-0000-000000000008', 'Pâte d''arachide', 'kg', 2000, 30, 8, 'Condiments'),
  ('e0000000-0000-0000-0000-000000000009', 'Tomates', 'kg', 500, 40, 10, 'Légumes'),
  ('e0000000-0000-0000-0000-000000000010', 'Oignons', 'kg', 400, 35, 10, 'Légumes'),
  ('e0000000-0000-0000-0000-000000000011', 'Gingembre', 'kg', 1000, 15, 3, 'Épices'),
  ('e0000000-0000-0000-0000-000000000012', 'Haricots niébé', 'kg', 800, 50, 10, 'Légumineuses');

-- Suppliers
INSERT INTO suppliers (id, name, contact_name, phone, email, address, city) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'Marché Central Douala', 'Amadou Bello', '+237 677 100 100', 'abello@marche.cm', 'Marché Central', 'Douala'),
  ('f0000000-0000-0000-0000-000000000002', 'Ferme Avicole du Moungo', 'Berthe Tchoua', '+237 677 200 200', 'btchoua@ferme.cm', 'Route de Nkongsamba', 'Douala'),
  ('f0000000-0000-0000-0000-000000000003', 'Pêcherie du Wouri', 'Samuel Ndongo', '+237 677 300 300', 'sndongo@peche.cm', 'Port de pêche, Bonabéri', 'Douala');

-- Supplier Ingredients
INSERT INTO supplier_ingredients (supplier_id, ingredient_id, supply_price, delivery_delay_days) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 1200, 1),
  ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003', 1800, 1),
  ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000009', 400, 1),
  ('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000010', 350, 1),
  ('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000004', 3200, 2),
  ('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000002', 4500, 1),
  ('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000005', 3500, 1);

-- Menus (1 week, Monday to Friday, lunch)
INSERT INTO menus (id, name, date, meal_type, is_published) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Menu Lundi', '2026-03-02', 'dejeuner', true),
  ('c0000000-0000-0000-0000-000000000002', 'Menu Mardi', '2026-03-03', 'dejeuner', true),
  ('c0000000-0000-0000-0000-000000000003', 'Menu Mercredi', '2026-03-04', 'dejeuner', true),
  ('c0000000-0000-0000-0000-000000000004', 'Menu Jeudi', '2026-03-05', 'dejeuner', true),
  ('c0000000-0000-0000-0000-000000000005', 'Menu Vendredi', '2026-03-06', 'dejeuner', true);

-- Menu Items
INSERT INTO menu_items (menu_id, dish_id, is_main_course, max_quantity) VALUES
  -- Lundi
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', true, 50),
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000010', true, 50),
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000013', false, 30),
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000015', false, 40),
  -- Mardi
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000003', true, 50),
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000007', true, 40),
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000013', false, 30),
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000014', false, 60),
  -- Mercredi
  ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000002', true, 50),
  ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000004', true, 40),
  ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000006', false, 30),
  ('c0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000015', false, 40),
  -- Jeudi
  ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000008', true, 45),
  ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000012', true, 45),
  ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000013', false, 30),
  ('c0000000-0000-0000-0000-000000000004', 'd0000000-0000-0000-0000-000000000014', false, 60),
  -- Vendredi
  ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000009', true, 50),
  ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000011', true, 50),
  ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000006', false, 30),
  ('c0000000-0000-0000-0000-000000000005', 'd0000000-0000-0000-0000-000000000015', false, 40);

-- Weekly Plan
INSERT INTO weekly_plans (id, week_start_date, week_end_date, is_validated) VALUES
  ('cc000000-0000-0000-0000-000000000001', '2026-03-02', '2026-03-06', true);

INSERT INTO weekly_plan_items (weekly_plan_id, menu_id, day_of_week) VALUES
  ('cc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 1),
  ('cc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 2),
  ('cc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 3),
  ('cc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 4),
  ('cc000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 5);

-- Formulas
INSERT INTO formulas (name, description, price, dishes_included) VALUES
  ('Formule Standard', '1 plat principal + 1 boisson', 2500, 2),
  ('Formule Complète', '1 entrée + 1 plat principal + 1 dessert + 1 boisson', 3500, 4),
  ('Formule Premium', '1 entrée + 1 plat principal + 1 accompagnement + 1 dessert + 1 boisson', 4500, 5);

-- App Config
INSERT INTO app_config (key, value, description) VALUES
  ('app_name', 'MILY''S Gourmet', 'Nom de l''application'),
  ('currency', 'FCFA', 'Devise utilisée'),
  ('default_meal_type', 'dejeuner', 'Type de repas par défaut'),
  ('order_cutoff_time', '09:00', 'Heure limite de commande'),
  ('delivery_start_time', '11:30', 'Heure de début des livraisons'),
  ('tax_rate', '19.25', 'Taux de TVA en pourcentage'),
  ('contact_email', 'contact@milys-gourmet.cm', 'Email de contact'),
  ('contact_phone', '+237 699 000 000', 'Téléphone de contact');

-- Dish Allergens
INSERT INTO dish_allergens (dish_id, allergen_name) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'Crustacés'),
  ('d0000000-0000-0000-0000-000000000001', 'Arachides'),
  ('d0000000-0000-0000-0000-000000000005', 'Gluten'),
  ('d0000000-0000-0000-0000-000000000010', 'Arachides'),
  ('d0000000-0000-0000-0000-000000000012', 'Arachides');

-- Dish Ingredients
INSERT INTO dish_ingredients (dish_id, ingredient_id, quantity_needed) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 0.3),
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000002', 0.15),
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003', 0.5),
  ('d0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000008', 0.1),
  ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000004', 0.5),
  ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003', 0.5),
  ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000009', 0.2),
  ('d0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000010', 0.15),
  ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000005', 0.5),
  ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000009', 0.2),
  ('d0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000010', 0.1),
  ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000007', 0.3),
  ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000008', 0.15),
  ('d0000000-0000-0000-0000-000000000010', 'e0000000-0000-0000-0000-000000000004', 0.3);

-- NOTE: Les 20 profiles employés doivent être créés après inscription via Supabase Auth.
-- Voici un template pour les insérer manuellement après création des users auth:
--
-- INSERT INTO profiles (id, email, full_name, phone, company_id, site_id) VALUES
--   ('<auth_user_uuid>', 'amadou.diallo@bollore.cm', 'Amadou Diallo', '+237 677 101 001', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001'),
--   ('<auth_user_uuid>', 'fatou.mbeki@bollore.cm', 'Fatou Mbeki', '+237 677 101 002', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001'),
--   ('<auth_user_uuid>', 'claude.nkoulou@bollore.cm', 'Claude Nkoulou', '+237 677 101 003', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002'),
--   ('<auth_user_uuid>', 'rose.atangana@bollore.cm', 'Rose Atangana', '+237 677 101 004', 'a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002'),
--   ('<auth_user_uuid>', 'michel.fotso@orange.cm', 'Michel Fotso', '+237 677 102 001', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000003'),
--   ('<auth_user_uuid>', 'grace.ngono@orange.cm', 'Grace Ngono', '+237 677 102 002', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000003'),
--   ('<auth_user_uuid>', 'thierry.tamba@orange.cm', 'Thierry Tamba', '+237 677 102 003', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000004'),
--   ('<auth_user_uuid>', 'sandrine.bella@orange.cm', 'Sandrine Bella', '+237 677 102 004', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000004'),
--   ('<auth_user_uuid>', 'eric.mvondo@orange.cm', 'Eric Mvondo', '+237 677 102 005', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000003'),
--   ('<auth_user_uuid>', 'celine.nanga@orange.cm', 'Céline Nanga', '+237 677 102 006', 'a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000004'),
--   ('<auth_user_uuid>', 'pierre.simo@socgen.cm', 'Pierre Simo', '+237 677 103 001', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000005'),
--   ('<auth_user_uuid>', 'alice.mbarga@socgen.cm', 'Alice Mbarga', '+237 677 103 002', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000005'),
--   ('<auth_user_uuid>', 'david.tchinda@socgen.cm', 'David Tchinda', '+237 677 103 003', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000006'),
--   ('<auth_user_uuid>', 'nathalie.ebode@socgen.cm', 'Nathalie Ebode', '+237 677 103 004', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000006'),
--   ('<auth_user_uuid>', 'olivier.manga@socgen.cm', 'Olivier Manga', '+237 677 103 005', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000005'),
--   ('<auth_user_uuid>', 'sylvie.onana@socgen.cm', 'Sylvie Onana', '+237 677 103 006', 'a0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000006'),
--   -- Staff MILY'S
--   ('<auth_user_uuid>', 'admin@milys-gourmet.cm', 'Admin MILY''S', '+237 699 000 001', NULL, NULL),
--   ('<auth_user_uuid>', 'chef@milys-gourmet.cm', 'Chef Marcel Ndjock', '+237 699 000 002', NULL, NULL),
--   ('<auth_user_uuid>', 'logistique@milys-gourmet.cm', 'Joseph Kamdem', '+237 699 000 003', NULL, NULL),
--   ('<auth_user_uuid>', 'caisse@milys-gourmet.cm', 'Yvette Nguema', '+237 699 000 004', NULL, NULL);
--
-- INSERT INTO user_roles (user_id, role) VALUES
--   ('<admin_uuid>', 'superadmin'),
--   ('<chef_uuid>', 'milys_kitchen'),
--   ('<logistique_uuid>', 'milys_logistics'),
--   ('<caisse_uuid>', 'milys_cashier'),
--   -- Employees get 'employee' role
--   -- Company admins get 'company_admin' role

// ============================================================
// MILY'S Gourmet — TypeScript types
// ============================================================

export type UserRole =
  | "superadmin"
  | "milys_admin"
  | "milys_kitchen"
  | "milys_logistics"
  | "milys_cashier"
  | "company_admin"
  | "company_cashier"
  | "third_party_cashier"
  | "employee"

export type OrderStatus =
  | "pending"
  | "confirmed"
  | "in_preparation"
  | "ready"
  | "in_delivery"
  | "delivered"
  | "cancelled"

export type DeliveryStatus =
  | "pending"
  | "assigned"
  | "picked_up"
  | "in_transit"
  | "delivered"
  | "failed"

export type PaymentStatus = "pending" | "partial" | "paid" | "overdue" | "refunded"
export type PaymentMethod = "mobile_money" | "cash" | "bank_transfer" | "card"
export type MealType = "breakfast" | "lunch" | "dinner" | "snack"
export type ContractType = "forfait" | "a_la_carte" | "mixed"
export type StockMovementType = "in" | "out" | "adjustment" | "waste"

// ============================================================
// COMPANY
// ============================================================

export interface Company {
  id: string
  name: string
  logo_url?: string
  industry?: string
  address?: string
  city: string
  phone?: string
  email?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface CompanySite {
  id: string
  company_id: string
  name: string
  address: string
  city: string
  latitude?: number
  longitude?: number
  delivery_time?: string
  is_active: boolean
  created_at: string
  updated_at: string
  company?: Company
}

export interface CompanyContract {
  id: string
  company_id: string
  contract_type: ContractType
  start_date: string
  end_date?: string
  daily_budget_per_employee?: number
  monthly_budget?: number
  subsidy_percentage?: number
  is_active: boolean
  created_at: string
  updated_at: string
  company?: Company
}

// ============================================================
// USER / PROFILE
// ============================================================

export interface Profile {
  id: string
  user_id: string
  full_name: string
  email: string
  phone?: string
  avatar_url?: string
  company_id?: string
  site_id?: string
  role: UserRole
  employee_code?: string
  qr_code?: string
  badge_number?: string
  department?: string
  is_active: boolean
  created_at: string
  updated_at: string
  company?: Company
  site?: CompanySite
}

// ============================================================
// DISH / MENU
// ============================================================

export interface Dish {
  id: string
  name: string
  description?: string
  category: string
  price: number
  image_url?: string
  preparation_time?: number
  calories?: number
  is_vegetarian: boolean
  is_available: boolean
  created_at: string
  updated_at: string
}

export interface Menu {
  id: string
  date: string
  meal_type: MealType
  site_id?: string
  is_published: boolean
  created_at: string
  updated_at: string
  items?: MenuItem[]
}

export interface MenuItem {
  id: string
  menu_id: string
  dish_id: string
  is_main: boolean
  quantity_available?: number
  created_at: string
  updated_at: string
  dish?: Dish
}

// ============================================================
// ORDER
// ============================================================

export interface Order {
  id: string
  user_id: string
  menu_id: string
  site_id?: string
  status: OrderStatus
  special_instructions?: string
  total_amount: number
  is_paid: boolean
  created_at: string
  updated_at: string
  profile?: Profile
  menu?: Menu
  items?: OrderItem[]
}

export interface OrderItem {
  id: string
  order_id: string
  dish_id: string
  quantity: number
  unit_price: number
  total_price: number
  created_at: string
  updated_at: string
  dish?: Dish
}

// ============================================================
// INVOICE / PAYMENT
// ============================================================

export interface Invoice {
  id: string
  company_id: string
  period_start: string
  period_end: string
  subtotal: number
  tax_amount: number
  total_amount: number
  status: PaymentStatus
  due_date?: string
  paid_at?: string
  created_at: string
  updated_at: string
  company?: Company
  items?: InvoiceItem[]
  payments?: Payment[]
}

export interface InvoiceItem {
  id: string
  invoice_id: string
  description: string
  quantity: number
  unit_price: number
  total_price: number
  created_at: string
  updated_at: string
}

export interface Payment {
  id: string
  invoice_id: string
  amount: number
  method: PaymentMethod
  reference?: string
  paid_at: string
  created_at: string
  updated_at: string
}

// ============================================================
// DELIVERY
// ============================================================

export interface Driver {
  id: string
  profile_id: string
  vehicle_type: string
  license_plate?: string
  is_available: boolean
  created_at: string
  updated_at: string
  profile?: Profile
}

export interface Delivery {
  id: string
  order_id: string
  driver_id?: string
  site_id: string
  status: DeliveryStatus
  pickup_time?: string
  delivery_time?: string
  notes?: string
  created_at: string
  updated_at: string
  order?: Order
  driver?: Driver
  site?: CompanySite
}

// ============================================================
// STOCK
// ============================================================

export interface Ingredient {
  id: string
  name: string
  unit: string
  current_stock: number
  min_stock_alert: number
  cost_per_unit: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface StockMovement {
  id: string
  ingredient_id: string
  movement_type: StockMovementType
  quantity: number
  reason?: string
  created_by: string
  created_at: string
  updated_at: string
  ingredient?: Ingredient
}

// ============================================================
// PRODUCTION
// ============================================================

export interface ProductionBatch {
  id: string
  dish_id: string
  menu_id?: string
  planned_quantity: number
  actual_quantity?: number
  started_at?: string
  completed_at?: string
  notes?: string
  created_at: string
  updated_at: string
  dish?: Dish
}

// ============================================================
// NOTIFICATIONS
// ============================================================

export interface Notification {
  id: string
  user_id: string
  title: string
  body: string
  type: "info" | "success" | "warning" | "error"
  is_read: boolean
  action_url?: string
  created_at: string
  updated_at: string
}

// ============================================================
// QR CODE
// ============================================================

export interface QRCode {
  id: string
  user_id: string
  code: string
  is_active: boolean
  last_scanned_at?: string
  created_at: string
  updated_at: string
}

// ============================================================
// API / QUERY helpers
// ============================================================

export interface PaginationParams {
  page: number
  limit: number
}

export interface FilterParams {
  search?: string
  status?: string
  dateFrom?: string
  dateTo?: string
  companyId?: string
  siteId?: string
}

export interface ApiResponse<T> {
  data: T
  count?: number
  error?: string
}

export const ROLE_LABELS: Record<UserRole, string> = {
  superadmin: "Super Admin",
  milys_admin: "Admin MILY'S",
  milys_kitchen: "Cuisine",
  milys_logistics: "Logistique",
  milys_cashier: "Caissier MILY'S",
  company_admin: "Admin Entreprise",
  company_cashier: "Caissier Entreprise",
  third_party_cashier: "Caissier Tiers",
  employee: "Employé",
}

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

export type OrderStatus = "confirmed" | "served" | "no_show" | "cancelled"

export type DeliveryStatus =
  | "scheduled"
  | "in_transit"
  | "delivered"
  | "failed"

export type PaymentStatus = "pending" | "partial" | "paid" | "overdue" | "refunded"
export type PaymentMethod = "salary_deduction" | "orange_money" | "wave" | "mtn_money" | "djamo" | "cash" | "ticket" | "bank_transfer"
export type MealType = "breakfast" | "lunch" | "dinner" | "snack"
export type ContractPaymentMode = "invoice" | "tickets"
export type StockMovementType = "entry" | "exit" | "adjustment" | "waste" | "return"
export type WeeklyPlanStatus = "draft" | "confirmed" | "locked"

// ============================================================
// COMPANY
// ============================================================

export interface Company {
  id: string
  name: string
  slug: string
  logo_url?: string
  industry?: string
  address?: string
  city: string
  contact_name?: string
  contact_email?: string
  contact_phone?: string
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
  capacity_per_day: number
  delivery_window_start?: string
  delivery_window_end?: string
  is_active: boolean
  created_at: string
  updated_at: string
  company?: Company
}

export interface CompanyContract {
  id: string
  company_id: string
  subsidy_rate: number
  base_meal_price: number
  max_meals_per_day: number
  max_budget_monthly?: number
  allowed_formulas: string[]
  working_days: number
  payment_mode: ContractPaymentMode
  tickets_per_month?: number
  advance_weeks: number
  start_date: string
  end_date?: string
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
  email: string
  full_name: string
  phone?: string
  avatar_url?: string
  employee_type: "regular" | "intern" | "guard" | "walk_in"
  matricule?: string
  company_id?: string
  site_id?: string
  badge_number?: string
  department?: string
  ticket_balance: number
  allergens: string[]
  preferences: string[]
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
  category: "ivoirien" | "international" | "entree" | "dessert" | "boisson" | "extra"
  price: number
  cost_price?: number
  photo_url?: string
  is_available: boolean
  is_starter: boolean
  is_extra: boolean
  preparation_time_min?: number
  calories?: number
  is_vegetarian: boolean
  is_vegan: boolean
  is_featured: boolean
  sort_order: number
  created_at: string
  updated_at: string
}

export interface Menu {
  id: string
  name: string
  week_start: string
  week_end: string
  is_published: boolean
  selection_deadline?: string
  notes?: string
  created_at: string
  updated_at: string
  items?: MenuItem[]
}

export interface MenuItem {
  id: string
  menu_id: string
  dish_id: string
  day_of_week: number
  is_starter: boolean
  sort_order: number
  max_quantity?: number
  created_at: string
  dish?: Dish
}

// ============================================================
// WEEKLY PLAN
// ============================================================

export interface ExtraItem {
  dish_id: string
  quantity: number
  unit_price: number
}

export interface WeeklyPlan {
  id: string
  user_id: string
  menu_id: string
  status: WeeklyPlanStatus
  locked_at?: string
  confirmed_at?: string
  created_at: string
  updated_at: string
  menu?: Menu
  items?: WeeklyPlanItem[]
}

export interface WeeklyPlanItem {
  id: string
  weekly_plan_id: string
  day_of_week: number
  dish_id: string
  extras: ExtraItem[]
  is_locked: boolean
  locked_at?: string
  is_cancelled: boolean
  cancel_reason?: string
  created_at: string
  dish?: Dish
}

// ============================================================
// ORDER
// ============================================================

export interface Order {
  id: string
  user_id: string
  dish_id: string
  site_id?: string
  order_date: string
  extras: ExtraItem[]
  status: OrderStatus
  total_price: number
  company_share: number
  employee_share: number
  ticket_used: boolean
  special_instructions?: string
  served_at?: string
  created_at: string
  updated_at: string
  dish?: Dish
  profile?: Profile
}

// ============================================================
// QR CODE
// ============================================================

export interface QRCode {
  id: string
  user_id: string
  order_id: string
  code: string
  is_used: boolean
  expires_at: string
  scanned_by?: string
  scanned_at?: string
  created_at: string
}

export interface QRScan {
  id: string
  qr_code_id: string
  scanned_by: string
  site_id?: string
  scan_type: "qr" | "manual" | "ticket"
  result: "success" | "already_used" | "expired" | "not_found"
  scanned_at: string
  notes?: string
}

// ============================================================
// INVOICE / PAYMENT
// ============================================================

export interface Invoice {
  id: string
  company_id: string
  invoice_number: string
  period_start: string
  period_end: string
  total_amount: number
  total_meals?: number
  status: "draft" | "sent" | "paid" | "overdue" | "cancelled"
  due_date?: string
  sent_at?: string
  paid_at?: string
  pdf_url?: string
  notes?: string
  created_at: string
  company?: Company
}

export interface Payment {
  id: string
  user_id?: string
  company_id?: string
  amount: number
  payment_method: PaymentMethod
  reference?: string
  status: "pending" | "completed" | "failed" | "refunded"
  payment_type: "employee" | "company" | "walk_in"
  completed_at?: string
  created_at: string
}

// ============================================================
// DELIVERY
// ============================================================

export interface Driver {
  id: string
  full_name: string
  phone: string
  vehicle_info?: string
  is_available: boolean
  created_at: string
}

export interface Delivery {
  id: string
  delivery_date: string
  site_id: string
  driver_id?: string
  status: DeliveryStatus
  departure_time?: string
  arrival_time?: string
  notes?: string
  created_at: string
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
  min_stock: number
  cost_per_unit: number
  category?: string
  supplier_id?: string
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface StockMovement {
  id: string
  ingredient_id: string
  movement_type: StockMovementType
  quantity: number
  balance_after?: number
  reason?: string
  reference_id?: string
  performed_by?: string
  created_at: string
  ingredient?: Ingredient
}

// ============================================================
// PRODUCTION
// ============================================================

export interface ProductionBatch {
  id: string
  production_date: string
  site_id: string
  dish_id: string
  planned_quantity: number
  produced_quantity?: number
  status: "planned" | "in_progress" | "completed"
  stock_deducted: boolean
  created_at: string
  dish?: Dish
}

// ============================================================
// NOTIFICATIONS
// ============================================================

export interface Notification {
  id: string
  user_id: string
  title: string
  message: string
  type: "info" | "success" | "warning" | "error"
  is_read: boolean
  link?: string
  created_at: string
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
  employee: "Employe",
}

// ============================================================
// Helpers
// ============================================================

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  confirmed: "Confirmee",
  served: "Servie",
  no_show: "Absent",
  cancelled: "Annulee",
}

export const DAY_LABELS: Record<number, string> = {
  1: "Lundi",
  2: "Mardi",
  3: "Mercredi",
  4: "Jeudi",
  5: "Vendredi",
  6: "Samedi",
}

export const DAY_SHORT_LABELS: Record<number, string> = {
  1: "Lun",
  2: "Mar",
  3: "Mer",
  4: "Jeu",
  5: "Ven",
  6: "Sam",
}

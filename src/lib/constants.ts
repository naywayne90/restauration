import type { UserRole } from "./types"

export const APP_NAME = "MILY'S Gourmet"
export const APP_DESCRIPTION = "Application de restauration d'entreprise"
export const CURRENCY = "FCFA"

// Role-based navigation config
export const ROLE_HOME_ROUTES: Record<UserRole, string> = {
  superadmin: "/app/admin/dashboard",
  milys_admin: "/app/admin/dashboard",
  milys_kitchen: "/app/kitchen/production",
  milys_logistics: "/app/admin/deliveries",
  milys_cashier: "/app/cashier/scan",
  company_admin: "/app/admin/companies",
  company_cashier: "/app/cashier/scan",
  third_party_cashier: "/app/cashier/scan",
  employee: "/app/employee/dashboard",
}

export const ADMIN_ROLES: UserRole[] = [
  "superadmin",
  "milys_admin",
  "milys_logistics",
]

export const KITCHEN_ROLES: UserRole[] = ["milys_kitchen"]

export const CASHIER_ROLES: UserRole[] = [
  "milys_cashier",
  "company_cashier",
  "third_party_cashier",
]

export const COMPANY_ADMIN_ROLES: UserRole[] = ["company_admin"]
export const EMPLOYEE_ROLES: UserRole[] = ["employee"]

// Admin sidebar navigation
export const ADMIN_NAV = [
  { path: "/app/admin/dashboard", label: "Tableau de bord", icon: "LayoutDashboard" },
  { path: "/app/admin/companies", label: "Entreprises", icon: "Building2" },
  { path: "/app/admin/employees", label: "Employés", icon: "Users" },
  { path: "/app/admin/dishes", label: "Plats", icon: "UtensilsCrossed" },
  { path: "/app/admin/menus", label: "Menus", icon: "BookOpen" },
  { path: "/app/admin/orders", label: "Commandes", icon: "ShoppingCart" },
  { path: "/app/admin/invoices", label: "Factures", icon: "FileText" },
  { path: "/app/admin/deliveries", label: "Livraisons", icon: "Truck" },
  { path: "/app/admin/suppliers", label: "Fournisseurs", icon: "Package" },
  { path: "/app/admin/stock", label: "Stock", icon: "BarChart3" },
  { path: "/app/admin/settings", label: "Paramètres", icon: "Settings" },
]

// Employee sidebar navigation
export const EMPLOYEE_NAV = [
  { path: "/app/employee/dashboard", label: "Tableau de bord", icon: "Home" },
  { path: "/app/employee/menu", label: "Menu de la semaine", icon: "UtensilsCrossed" },
  { path: "/app/employee/orders", label: "Mes commandes", icon: "ShoppingCart" },
  { path: "/app/employee/qrcode", label: "Mon QR Code", icon: "QrCode" },
  { path: "/app/employee/profile", label: "Mon profil", icon: "User" },
]

// Kitchen sidebar navigation
export const KITCHEN_NAV = [
  { path: "/app/kitchen/production", label: "Production du jour", icon: "ChefHat" },
  { path: "/app/kitchen/stock", label: "Alertes stock", icon: "AlertTriangle" },
]

// Cashier sidebar navigation
export const CASHIER_NAV = [
  { path: "/app/cashier/scan", label: "Scanner QR", icon: "QrCode" },
  { path: "/app/cashier/report", label: "Rapport journalier", icon: "BarChart3" },
]

// Order status labels and colors
export const ORDER_STATUS_CONFIG = {
  confirmed: { label: "Confirmee", color: "bg-blue-100 text-blue-800", icon: "Clock" },
  served: { label: "Servie", color: "bg-green-100 text-green-800", icon: "CheckCircle2" },
  no_show: { label: "Absent", color: "bg-yellow-100 text-yellow-800", icon: "UserX" },
  cancelled: { label: "Annulee", color: "bg-red-100 text-red-800", icon: "XCircle" },
} as const

// Payment status labels and colors
export const PAYMENT_STATUS_CONFIG = {
  pending: { label: "En attente", color: "bg-yellow-100 text-yellow-800" },
  partial: { label: "Partiel", color: "bg-orange-100 text-orange-800" },
  paid: { label: "Paye", color: "bg-green-100 text-green-800" },
  overdue: { label: "En retard", color: "bg-red-100 text-red-800" },
  refunded: { label: "Rembourse", color: "bg-gray-100 text-gray-800" },
}

// Business rules
export const LOCK_HOURS_BEFORE = 72 // J-3 = 72h avant le jour du repas
export const BASE_MEAL_PRICE = 5000 // FCFA
export const QR_VALID_START = "11:00"
export const QR_VALID_END = "14:00"

// Allergens list
export const ALLERGEN_OPTIONS = [
  "Arachides",
  "Gluten",
  "Lait",
  "Oeufs",
  "Poisson",
  "Crustaces",
  "Soja",
  "Fruits a coque",
  "Celeri",
  "Moutarde",
  "Sesame",
  "Sulfites",
]

// Preference options
export const PREFERENCE_OPTIONS = [
  "Vegetarien",
  "Vegan",
  "Sans porc",
  "Sans alcool",
  "Halal",
  "Faible en sel",
  "Sans piment",
  "Sans oignon",
]

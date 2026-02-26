import type { UserRole } from "./types"

export const APP_NAME = "MILY'S Gourmet"
export const APP_DESCRIPTION = "Application de restauration d'entreprise"
export const CURRENCY = "FCFA"

// Role-based navigation config
export const ROLE_HOME_ROUTES: Record<UserRole, string> = {
  superadmin: "/admin/dashboard",
  milys_admin: "/admin/dashboard",
  milys_kitchen: "/kitchen/production",
  milys_logistics: "/admin/deliveries",
  milys_cashier: "/cashier/scan",
  company_admin: "/admin/companies",
  company_cashier: "/cashier/scan",
  third_party_cashier: "/cashier/scan",
  employee: "/employee/dashboard",
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
  { path: "/admin/dashboard", label: "Tableau de bord", icon: "LayoutDashboard" },
  { path: "/admin/companies", label: "Entreprises", icon: "Building2" },
  { path: "/admin/employees", label: "Employés", icon: "Users" },
  { path: "/admin/dishes", label: "Plats", icon: "UtensilsCrossed" },
  { path: "/admin/menus", label: "Menus", icon: "BookOpen" },
  { path: "/admin/orders", label: "Commandes", icon: "ShoppingCart" },
  { path: "/admin/invoices", label: "Factures", icon: "FileText" },
  { path: "/admin/deliveries", label: "Livraisons", icon: "Truck" },
  { path: "/admin/suppliers", label: "Fournisseurs", icon: "Package" },
  { path: "/admin/stock", label: "Stock", icon: "BarChart3" },
  { path: "/admin/settings", label: "Paramètres", icon: "Settings" },
]

// Employee sidebar navigation
export const EMPLOYEE_NAV = [
  { path: "/employee/dashboard", label: "Tableau de bord", icon: "Home" },
  { path: "/employee/menu", label: "Menu de la semaine", icon: "UtensilsCrossed" },
  { path: "/employee/orders", label: "Mes commandes", icon: "ShoppingCart" },
  { path: "/employee/qrcode", label: "Mon QR Code", icon: "QrCode" },
  { path: "/employee/profile", label: "Mon profil", icon: "User" },
]

// Kitchen sidebar navigation
export const KITCHEN_NAV = [
  { path: "/kitchen/production", label: "Production du jour", icon: "ChefHat" },
  { path: "/kitchen/stock", label: "Alertes stock", icon: "AlertTriangle" },
]

// Cashier sidebar navigation
export const CASHIER_NAV = [
  { path: "/cashier/scan", label: "Scanner QR", icon: "QrCode" },
  { path: "/cashier/report", label: "Rapport journalier", icon: "BarChart3" },
]

// Order status labels and colors
export const ORDER_STATUS_CONFIG = {
  pending: { label: "En attente", color: "bg-yellow-100 text-yellow-800" },
  confirmed: { label: "Confirmée", color: "bg-blue-100 text-blue-800" },
  in_preparation: { label: "En préparation", color: "bg-orange-100 text-orange-800" },
  ready: { label: "Prête", color: "bg-green-100 text-green-800" },
  in_delivery: { label: "En livraison", color: "bg-purple-100 text-purple-800" },
  delivered: { label: "Livrée", color: "bg-gray-100 text-gray-800" },
  cancelled: { label: "Annulée", color: "bg-red-100 text-red-800" },
}

// Payment status labels and colors
export const PAYMENT_STATUS_CONFIG = {
  pending: { label: "En attente", color: "bg-yellow-100 text-yellow-800" },
  partial: { label: "Partiel", color: "bg-orange-100 text-orange-800" },
  paid: { label: "Payé", color: "bg-green-100 text-green-800" },
  overdue: { label: "En retard", color: "bg-red-100 text-red-800" },
  refunded: { label: "Remboursé", color: "bg-gray-100 text-gray-800" },
}

import { useState } from "react"
import { Outlet, useLocation } from "react-router-dom"
import { Sidebar } from "./Sidebar"
import { Header } from "./Header"
import { MobileNav } from "./MobileNav"
import { ADMIN_NAV, KITCHEN_NAV, CASHIER_NAV } from "@/lib/constants"
import { useAuth } from "@/hooks/use-auth"
import { cn } from "@/lib/utils"

const PAGE_TITLES: Record<string, string> = {
  "/app/admin/dashboard": "Tableau de bord",
  "/app/admin/companies": "Entreprises",
  "/app/admin/employees": "Employés",
  "/app/admin/dishes": "Plats",
  "/app/admin/menus": "Menus",
  "/app/admin/orders": "Commandes",
  "/app/admin/invoices": "Factures",
  "/app/admin/deliveries": "Livraisons",
  "/app/admin/suppliers": "Fournisseurs",
  "/app/admin/stock": "Stock",
  "/app/admin/settings": "Paramètres",
  "/app/kitchen/production": "Production du jour",
  "/app/kitchen/stock": "Alertes stock",
  "/app/cashier/scan": "Scanner QR Code",
  "/app/cashier/report": "Rapport journalier",
}

function getNavItems(roles: string[]) {
  if (roles.some((r) => ["milys_kitchen"].includes(r))) return KITCHEN_NAV
  if (roles.some((r) => ["milys_cashier", "company_cashier", "third_party_cashier"].includes(r))) return CASHIER_NAV
  return ADMIN_NAV
}

export function AdminLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const { user } = useAuth()
  const location = useLocation()

  const navItems = getNavItems(user?.roles ?? [])
  const pageTitle = PAGE_TITLES[location.pathname] || "MILY'S Gourmet"

  return (
    <div className="flex h-screen overflow-hidden bg-background">
      {/* Desktop Sidebar */}
      <div className="hidden md:flex">
        <Sidebar
          navItems={navItems}
          collapsed={collapsed}
          onToggle={() => setCollapsed((c) => !c)}
        />
      </div>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header
          title={pageTitle}
          onMenuToggle={() => setCollapsed((c) => !c)}
          showSearch
        />

        <main
          className={cn(
            "flex-1 overflow-y-auto p-4 md:p-6",
            "pb-20 md:pb-6" // Extra bottom padding for mobile nav
          )}
        >
          <Outlet />
        </main>
      </div>

      {/* Mobile bottom navigation */}
      <MobileNav navItems={navItems} />
    </div>
  )
}

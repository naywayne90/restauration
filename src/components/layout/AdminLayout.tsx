import { useState } from "react"
import { Outlet, useLocation } from "react-router-dom"
import { Sidebar } from "./Sidebar"
import { Header } from "./Header"
import { MobileNav } from "./MobileNav"
import { ADMIN_NAV, KITCHEN_NAV, CASHIER_NAV } from "@/lib/constants"
import { useAuth } from "@/hooks/use-auth"
import { cn } from "@/lib/utils"

const PAGE_TITLES: Record<string, string> = {
  "/admin/dashboard": "Tableau de bord",
  "/admin/companies": "Entreprises",
  "/admin/employees": "Employés",
  "/admin/dishes": "Plats",
  "/admin/menus": "Menus",
  "/admin/orders": "Commandes",
  "/admin/invoices": "Factures",
  "/admin/deliveries": "Livraisons",
  "/admin/suppliers": "Fournisseurs",
  "/admin/stock": "Stock",
  "/admin/settings": "Paramètres",
  "/kitchen/production": "Production du jour",
  "/kitchen/stock": "Alertes stock",
  "/cashier/scan": "Scanner QR Code",
  "/cashier/report": "Rapport journalier",
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

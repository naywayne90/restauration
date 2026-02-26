import { Outlet, useLocation } from "react-router-dom"
import { MobileNav } from "./MobileNav"
import { Header } from "./Header"
import { Sidebar } from "./Sidebar"
import { Sheet, SheetContent } from "@/components/ui/sheet"
import { EMPLOYEE_NAV } from "@/lib/constants"
import { useState } from "react"
import { cn } from "@/lib/utils"

const PAGE_TITLES: Record<string, string> = {
  "/app/employee/dashboard": "Mon tableau de bord",
  "/app/employee/menu": "Menu de la semaine",
  "/app/employee/orders": "Mes commandes",
  "/app/employee/qrcode": "Mon QR Code",
  "/app/employee/profile": "Mon profil",
}

export function EmployeeLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()
  const pageTitle = PAGE_TITLES[location.pathname] || "MILY'S Gourmet"

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      {/* Desktop Sidebar */}
      <div className="hidden md:flex">
        <Sidebar
          navItems={EMPLOYEE_NAV}
          collapsed={collapsed}
          onToggle={() => setCollapsed((c) => !c)}
        />
      </div>

      {/* Mobile Sidebar Sheet */}
      <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
        <SheetContent side="left" className="w-64 p-0 bg-sidebar border-sidebar-border">
          <Sidebar
            navItems={EMPLOYEE_NAV}
            onNavigate={() => setMobileOpen(false)}
          />
        </SheetContent>
      </Sheet>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header
          title={pageTitle}
          onMenuToggle={() => setMobileOpen(true)}
          notificationCount={2}
        />

        <main
          className={cn(
            "flex-1 overflow-y-auto p-4 md:p-6",
            "pb-20 md:pb-6"
          )}
        >
          <Outlet />
        </main>
      </div>

      {/* Mobile bottom navigation */}
      <MobileNav navItems={EMPLOYEE_NAV} />
    </div>
  )
}

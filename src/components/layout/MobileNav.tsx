import { NavLink } from "react-router-dom"
import {
  Home, UtensilsCrossed, ShoppingCart, QrCode, User,
  LayoutDashboard, Building2, Users, FileText, Truck,
  ChefHat, AlertTriangle, BarChart3,
} from "lucide-react"
import { cn } from "@/lib/utils"

const ICON_MAP: Record<string, React.ElementType> = {
  Home, UtensilsCrossed, ShoppingCart, QrCode, User,
  LayoutDashboard, Building2, Users, FileText, Truck,
  ChefHat, AlertTriangle, BarChart3,
}

interface NavItem {
  path: string
  label: string
  icon: string
}

interface MobileNavProps {
  navItems: NavItem[]
}

export function MobileNav({ navItems }: MobileNavProps) {
  // Show at most 5 items in the bottom nav
  const items = navItems.slice(0, 5)

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 border-t bg-background md:hidden">
      <div className="flex h-16 items-center justify-around px-2">
        {items.map((item) => {
          const Icon = ICON_MAP[item.icon] || Home
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                cn(
                  "flex flex-col items-center gap-1 px-3 py-2 text-xs font-medium transition-colors",
                  "min-w-0 flex-1",
                  isActive
                    ? "text-primary"
                    : "text-muted-foreground hover:text-foreground"
                )
              }
            >
              {({ isActive }) => (
                <>
                  <Icon className={cn("h-5 w-5", isActive && "fill-primary/20")} />
                  <span className="truncate">{item.label}</span>
                </>
              )}
            </NavLink>
          )
        })}
      </div>
    </nav>
  )
}

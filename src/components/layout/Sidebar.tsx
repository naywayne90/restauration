import { NavLink, useNavigate } from "react-router-dom"
import {
  LayoutDashboard, Building2, Users, UtensilsCrossed, BookOpen,
  ShoppingCart, FileText, Truck, Package, BarChart3, Settings,
  Home, QrCode, User, ChefHat, AlertTriangle, LogOut, ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { ScrollArea } from "@/components/ui/scroll-area"
import { useAuth } from "@/hooks/use-auth"
import { getInitials } from "@/lib/utils"
import { APP_NAME } from "@/lib/constants"

const ICON_MAP: Record<string, React.ElementType> = {
  LayoutDashboard, Building2, Users, UtensilsCrossed, BookOpen,
  ShoppingCart, FileText, Truck, Package, BarChart3, Settings,
  Home, QrCode, User, ChefHat, AlertTriangle,
}

interface NavItem {
  path: string
  label: string
  icon: string
}

interface SidebarProps {
  navItems: NavItem[]
  collapsed?: boolean
  onToggle?: () => void
  onNavigate?: () => void
}

export function Sidebar({ navItems, collapsed = false, onToggle, onNavigate }: SidebarProps) {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate("/login")
  }

  return (
    <aside
      className={cn(
        "flex flex-col bg-sidebar text-sidebar-foreground transition-all duration-300 border-r border-sidebar-border",
        collapsed ? "w-16" : "w-64"
      )}
    >
      {/* Logo */}
      <div className={cn(
        "flex h-16 items-center border-b border-sidebar-border px-4",
        collapsed ? "justify-center" : "justify-between"
      )}>
        {!collapsed && (
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
              <UtensilsCrossed className="h-4 w-4 text-white" />
            </div>
            <span className="text-sm font-bold text-white">{APP_NAME}</span>
          </div>
        )}
        {collapsed && (
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
            <UtensilsCrossed className="h-4 w-4 text-white" />
          </div>
        )}
        {onToggle && (
          <Button
            variant="ghost"
            size="icon"
            onClick={onToggle}
            className="h-7 w-7 text-sidebar-foreground hover:bg-sidebar-accent hover:text-white"
          >
            {collapsed ? (
              <ChevronRight className="h-4 w-4" />
            ) : (
              <ChevronLeft className="h-4 w-4" />
            )}
          </Button>
        )}
      </div>

      {/* Navigation */}
      <ScrollArea className="flex-1 py-4">
        <nav className="space-y-1 px-2">
          {navItems.map((item) => {
            const Icon = ICON_MAP[item.icon] || Home
            return (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={onNavigate}
                className={({ isActive }) =>
                  cn(
                    "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                    "hover:bg-sidebar-accent hover:text-white",
                    isActive
                      ? "bg-primary text-white"
                      : "text-sidebar-accent-foreground",
                    collapsed && "justify-center px-2"
                  )
                }
                title={collapsed ? item.label : undefined}
              >
                <Icon className="h-4 w-4 flex-shrink-0" />
                {!collapsed && <span>{item.label}</span>}
              </NavLink>
            )
          })}
        </nav>
      </ScrollArea>

      {/* User info */}
      <div className={cn(
        "border-t border-sidebar-border p-3",
        collapsed ? "flex justify-center" : ""
      )}>
        {!collapsed ? (
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-primary text-xs font-bold text-white">
              {user?.profile?.full_name
                ? getInitials(user.profile.full_name)
                : "?"}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-medium text-white">
                {user?.profile?.full_name || user?.user.email}
              </p>
              <p className="truncate text-xs text-slate-400">
                {user?.profile?.company?.name || user?.roles[0] || ""}
              </p>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={handleSignOut}
              className="h-7 w-7 flex-shrink-0 text-slate-400 hover:bg-sidebar-accent hover:text-white"
              title="Déconnexion"
            >
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        ) : (
          <Button
            variant="ghost"
            size="icon"
            onClick={handleSignOut}
            className="h-8 w-8 text-slate-400 hover:bg-sidebar-accent hover:text-white"
            title="Déconnexion"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        )}
      </div>
    </aside>
  )
}

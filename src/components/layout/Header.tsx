import { Link, useLocation, useNavigate } from "react-router-dom"
import { Bell, ChevronRight, LogOut, Menu, Search, User } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { cn, getInitials } from "@/lib/utils"
import { useAuth } from "@/hooks/use-auth"
import { ROLE_LABELS } from "@/lib/role-config"

interface HeaderProps {
  title: string
  onMenuToggle?: () => void
  showSearch?: boolean
  notificationCount?: number
  className?: string
}

const BREADCRUMB_MAP: Record<string, string> = {
  admin: "Administration",
  employee: "Espace employé",
  kitchen: "Cuisine",
  cashier: "Caisse",
  dashboard: "Tableau de bord",
  companies: "Entreprises",
  employees: "Employés",
  dishes: "Plats",
  menus: "Menus",
  orders: "Commandes",
  invoices: "Factures",
  deliveries: "Livraisons",
  suppliers: "Fournisseurs",
  stock: "Stock",
  settings: "Paramètres",
  production: "Production",
  scan: "Scanner",
  report: "Rapport",
  menu: "Menu",
  qrcode: "QR Code",
  profile: "Profil",
}

export function Header({
  title,
  onMenuToggle,
  showSearch = false,
  notificationCount = 0,
  className,
}: HeaderProps) {
  const { user, signOut } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()

  const handleSignOut = async () => {
    await signOut()
    navigate("/login")
  }

  // Build breadcrumb from pathname — skip "app" prefix
  const pathSegments = location.pathname.split("/").filter(Boolean)
  const breadcrumbSegments = pathSegments
    .filter((s) => s !== "app")
    .map((segment) => BREADCRUMB_MAP[segment] || segment)

  const initials = user?.profile?.full_name
    ? getInitials(user.profile.full_name)
    : "?"

  const primaryRole = user?.roles[0]
  const roleLabel = primaryRole ? ROLE_LABELS[primaryRole] : ""

  return (
    <header
      className={cn(
        "flex h-16 items-center gap-4 border-b bg-background px-4 md:px-6",
        className
      )}
    >
      {onMenuToggle && (
        <Button
          variant="ghost"
          size="icon"
          className="md:hidden"
          onClick={onMenuToggle}
        >
          <Menu className="h-5 w-5" />
        </Button>
      )}

      {/* Title + Breadcrumb */}
      <div className="flex-1 min-w-0">
        <h1 className="text-lg font-semibold truncate">{title}</h1>
        {breadcrumbSegments.length > 1 && (
          <nav className="hidden md:flex items-center gap-1 text-xs text-muted-foreground">
            {breadcrumbSegments.map((label, i) => (
              <span key={i} className="flex items-center gap-1">
                {i > 0 && <ChevronRight className="h-3 w-3" />}
                <span
                  className={cn(
                    i === breadcrumbSegments.length - 1 && "text-foreground font-medium"
                  )}
                >
                  {label}
                </span>
              </span>
            ))}
          </nav>
        )}
      </div>

      <div className="flex items-center gap-2">
        {showSearch && (
          <div className="hidden lg:block">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Rechercher..."
                className="w-64 pl-8 text-sm"
              />
            </div>
          </div>
        )}

        {/* Notifications */}
        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          {notificationCount > 0 && (
            <Badge
              className="absolute -right-1 -top-1 h-5 w-5 justify-center rounded-full p-0 text-xs"
              variant="destructive"
            >
              {notificationCount > 9 ? "9+" : notificationCount}
            </Badge>
          )}
        </Button>

        {/* Avatar dropdown */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="relative h-9 w-9 rounded-full">
              <Avatar className="h-9 w-9">
                <AvatarFallback className="bg-primary text-xs font-bold text-white">
                  {initials}
                </AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuLabel className="font-normal">
              <div className="flex flex-col space-y-1">
                <p className="text-sm font-medium">
                  {user?.profile?.full_name || user?.user.email}
                </p>
                <p className="text-xs text-muted-foreground">{roleLabel}</p>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem asChild>
              <Link to="/app/employee/profile" className="cursor-pointer">
                <User className="mr-2 h-4 w-4" />
                Mon profil
              </Link>
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              onClick={handleSignOut}
              className="cursor-pointer text-destructive focus:text-destructive"
            >
              <LogOut className="mr-2 h-4 w-4" />
              Déconnexion
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  )
}

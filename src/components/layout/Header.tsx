import { Bell, Menu, Search } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { cn } from "@/lib/utils"

interface HeaderProps {
  title: string
  onMenuToggle?: () => void
  showSearch?: boolean
  notificationCount?: number
  className?: string
}

export function Header({
  title,
  onMenuToggle,
  showSearch = false,
  notificationCount = 0,
  className,
}: HeaderProps) {
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

      <h1 className="flex-1 text-lg font-semibold truncate">{title}</h1>

      <div className="flex items-center gap-2">
        {showSearch && (
          <div className="hidden md:block">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Rechercher..."
                className="w-64 pl-8 text-sm"
              />
            </div>
          </div>
        )}

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
      </div>
    </header>
  )
}

"use client";

import React, { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Building2,
  Users,
  UtensilsCrossed,
  BookOpen,
  ShoppingCart,
  FileText,
  Truck,
  Package,
  Warehouse,
  Settings,
  Bell,
  Menu,
  LogOut,
  ChefHat,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Sheet, SheetContent, SheetTrigger, SheetTitle } from "@/components/ui/sheet";
import { Separator } from "@/components/ui/separator";

const navigation = [
  { name: "Dashboard", href: "/app/admin/dashboard", icon: LayoutDashboard },
  { name: "Entreprises", href: "/app/admin/companies", icon: Building2 },
  { name: "Employés", href: "/app/admin/employees", icon: Users },
  { name: "Plats", href: "/app/admin/dishes", icon: UtensilsCrossed },
  { name: "Menus", href: "/app/admin/menus", icon: BookOpen },
  { name: "Commandes", href: "/app/admin/orders", icon: ShoppingCart },
  { name: "Production", href: "/app/kitchen/production", icon: ChefHat },
  { name: "Livraisons", href: "/app/admin/deliveries", icon: Truck },
  { name: "Factures", href: "/app/admin/invoices", icon: FileText },
  { name: "Stock", href: "/app/admin/stock", icon: Package },
  { name: "Fournisseurs", href: "/app/admin/suppliers", icon: Warehouse },
  { name: "Configuration", href: "/app/admin/settings", icon: Settings },
];

function SidebarContent({ pathname }: { pathname: string }) {
  return (
    <div className="flex h-full flex-col">
      <div className="flex h-16 items-center gap-2 px-6">
        <UtensilsCrossed className="h-8 w-8 text-orange-500" />
        <span className="text-xl font-bold text-white">MILY&apos;S</span>
      </div>
      <Separator className="bg-slate-700" />
      <nav className="flex-1 space-y-1 px-3 py-4">
        {navigation.map((item) => {
          const isActive = pathname.startsWith(item.href);
          return (
            <Link
              key={item.name}
              href={item.href}
              className={cn(
                "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                isActive
                  ? "bg-orange-500/10 text-orange-500"
                  : "text-slate-400 hover:bg-slate-800 hover:text-white"
              )}
            >
              <item.icon className="h-5 w-5 shrink-0" />
              {item.name}
            </Link>
          );
        })}
      </nav>
      <div className="px-3 py-4">
        <Separator className="mb-4 bg-slate-700" />
        <Link
          href="/login"
          className="flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-slate-400 hover:bg-slate-800 hover:text-white transition-colors"
        >
          <LogOut className="h-5 w-5" />
          Déconnexion
        </Link>
      </div>
    </div>
  );
}

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Desktop sidebar */}
      <aside className="hidden lg:flex lg:w-64 lg:flex-col bg-[#0F172A]">
        <SidebarContent pathname={pathname} />
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <header className="flex h-16 items-center justify-between border-b bg-white px-4 lg:px-6">
          <div className="flex items-center gap-4">
            {/* Mobile menu */}
            <Sheet open={mobileOpen} onOpenChange={setMobileOpen}>
              <SheetTrigger asChild>
                <Button variant="ghost" size="icon" className="lg:hidden">
                  <Menu className="h-5 w-5" />
                </Button>
              </SheetTrigger>
              <SheetContent side="left" className="w-64 bg-[#0F172A] p-0 border-none">
                <SheetTitle className="sr-only">Navigation</SheetTitle>
                <SidebarContent pathname={pathname} />
              </SheetContent>
            </Sheet>
            <h1 className="text-lg font-semibold text-slate-900">
              {navigation.find((n) => pathname.startsWith(n.href))?.name || "Administration"}
            </h1>
          </div>
          <div className="flex items-center gap-3">
            <Button variant="ghost" size="icon" className="relative">
              <Bell className="h-5 w-5" />
              <span className="absolute right-1 top-1 h-2 w-2 rounded-full bg-orange-500" />
            </Button>
            <Avatar className="h-8 w-8">
              <AvatarFallback className="bg-orange-500 text-white text-sm">MA</AvatarFallback>
            </Avatar>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto bg-gray-50 p-4 lg:p-6">
          {children}
        </main>
      </div>
    </div>
  );
}

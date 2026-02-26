"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Home,
  BookOpen,
  QrCode,
  ShoppingCart,
  User,
  UtensilsCrossed,
} from "lucide-react";
import { cn } from "@/lib/utils";

const bottomNav = [
  { name: "Accueil", href: "/app/employee/dashboard", icon: Home },
  { name: "Menu", href: "/app/employee/menu", icon: BookOpen },
  { name: "QR Code", href: "/app/employee/qrcode", icon: QrCode },
  { name: "Commandes", href: "/app/employee/orders", icon: ShoppingCart },
  { name: "Profil", href: "/app/employee/profile", icon: User },
];

export default function EmployeeLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="flex min-h-screen flex-col bg-gray-50">
      {/* Header */}
      <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b bg-white px-4">
        <div className="flex items-center gap-2">
          <UtensilsCrossed className="h-6 w-6 text-orange-500" />
          <span className="text-lg font-bold">MILY&apos;S</span>
        </div>
      </header>

      {/* Page content */}
      <main className="flex-1 pb-20">
        {children}
      </main>

      {/* Bottom navigation */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 border-t bg-white">
        <div className="flex items-center justify-around py-2">
          {bottomNav.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link
                key={item.name}
                href={item.href}
                className={cn(
                  "flex flex-col items-center gap-1 px-3 py-1 text-xs font-medium transition-colors",
                  isActive ? "text-orange-500" : "text-gray-500"
                )}
              >
                <item.icon className={cn("h-5 w-5", isActive && "text-orange-500")} />
                {item.name}
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}

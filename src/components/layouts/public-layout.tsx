"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { UtensilsCrossed } from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";

const navLinks = [
  { name: "Accueil", href: "/gourmet" },
  { name: "Entreprises", href: "/gourmet/entreprises" },
  { name: "Comment ça marche", href: "/gourmet/comment-ca-marche" },
  { name: "Contact", href: "/gourmet/contact" },
];

export default function PublicLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  return (
    <div className="flex min-h-screen flex-col">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b bg-white/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link href="/gourmet" className="flex items-center gap-2">
            <UtensilsCrossed className="h-7 w-7 text-orange-500" />
            <span className="text-xl font-bold">MILY&apos;S Gourmet</span>
          </Link>

          <nav className="hidden md:flex items-center gap-6">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={cn(
                  "text-sm font-medium transition-colors",
                  pathname === link.href
                    ? "text-orange-500"
                    : "text-gray-600 hover:text-gray-900"
                )}
              >
                {link.name}
              </Link>
            ))}
          </nav>

          <Button asChild className="bg-orange-500 hover:bg-orange-600">
            <Link href="/login">Se connecter</Link>
          </Button>
        </div>
      </header>

      {/* Page content */}
      <main className="flex-1">{children}</main>

      {/* Footer */}
      <footer className="border-t bg-slate-900 text-white">
        <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 gap-8 md:grid-cols-3">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <UtensilsCrossed className="h-6 w-6 text-orange-500" />
                <span className="text-lg font-bold">MILY&apos;S Gourmet</span>
              </div>
              <p className="text-sm text-slate-400">
                La restauration d&apos;entreprise réinventée. Des repas frais et savoureux livrés chaque jour.
              </p>
            </div>
            <div>
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider">Navigation</h3>
              <ul className="space-y-2">
                {navLinks.map((link) => (
                  <li key={link.href}>
                    <Link href={link.href} className="text-sm text-slate-400 hover:text-white transition-colors">
                      {link.name}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h3 className="mb-4 text-sm font-semibold uppercase tracking-wider">Contact</h3>
              <ul className="space-y-2 text-sm text-slate-400">
                <li>Douala, Cameroun</li>
                <li>+237 6XX XXX XXX</li>
                <li>contact@milys-gourmet.cm</li>
              </ul>
            </div>
          </div>
          <div className="mt-8 border-t border-slate-800 pt-8 text-center text-sm text-slate-400">
            &copy; 2026 MILY&apos;S Gourmet. Tous droits réservés.
          </div>
        </div>
      </footer>
    </div>
  );
}

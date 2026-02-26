import { Outlet, NavLink, Link } from "react-router-dom"
import { UtensilsCrossed, Menu, X } from "lucide-react"
import { useState } from "react"
import { Button } from "@/components/ui/button"
import { APP_NAME } from "@/lib/constants"
import { cn } from "@/lib/utils"

const NAV_LINKS = [
  { path: "/", label: "Accueil" },
  { path: "/comment-ca-marche", label: "Comment ça marche" },
  { path: "/entreprises", label: "Pour les entreprises" },
  { path: "/contact", label: "Contact" },
]

export function PublicLayout() {
  const [mobileOpen, setMobileOpen] = useState(false)

  return (
    <div className="min-h-screen bg-white">
      {/* Navbar */}
      <header className="sticky top-0 z-50 border-b bg-white/95 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary">
              <UtensilsCrossed className="h-5 w-5 text-white" />
            </div>
            <span className="text-lg font-bold text-gray-900">{APP_NAME}</span>
          </Link>

          {/* Desktop nav */}
          <nav className="hidden md:flex items-center gap-6">
            {NAV_LINKS.map((link) => (
              <NavLink
                key={link.path}
                to={link.path}
                className={({ isActive }) =>
                  cn(
                    "text-sm font-medium transition-colors",
                    isActive ? "text-primary" : "text-gray-600 hover:text-gray-900"
                  )
                }
              >
                {link.label}
              </NavLink>
            ))}
          </nav>

          {/* CTA */}
          <div className="hidden md:flex items-center gap-3">
            <Button variant="ghost" asChild>
              <Link to="/login">Connexion</Link>
            </Button>
            <Button asChild>
              <Link to="/contact">Demander une démo</Link>
            </Button>
          </div>

          {/* Mobile menu toggle */}
          <Button
            variant="ghost"
            size="icon"
            className="md:hidden"
            onClick={() => setMobileOpen((o) => !o)}
          >
            {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </Button>
        </div>

        {/* Mobile menu */}
        {mobileOpen && (
          <div className="border-t bg-white px-4 py-4 md:hidden">
            <nav className="flex flex-col gap-3">
              {NAV_LINKS.map((link) => (
                <NavLink
                  key={link.path}
                  to={link.path}
                  onClick={() => setMobileOpen(false)}
                  className={({ isActive }) =>
                    cn(
                      "text-sm font-medium py-2",
                      isActive ? "text-primary" : "text-gray-700"
                    )
                  }
                >
                  {link.label}
                </NavLink>
              ))}
              <div className="flex gap-2 pt-2 border-t">
                <Button variant="outline" className="flex-1" asChild>
                  <Link to="/login" onClick={() => setMobileOpen(false)}>Connexion</Link>
                </Button>
                <Button className="flex-1" asChild>
                  <Link to="/contact" onClick={() => setMobileOpen(false)}>Démo</Link>
                </Button>
              </div>
            </nav>
          </div>
        )}
      </header>

      {/* Page content */}
      <main>
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="border-t bg-gray-50 py-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="flex flex-col items-center gap-4 md:flex-row md:justify-between">
            <div className="flex items-center gap-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
                <UtensilsCrossed className="h-4 w-4 text-white" />
              </div>
              <span className="font-bold text-gray-900">{APP_NAME}</span>
            </div>
            <p className="text-sm text-gray-500">
              © {new Date().getFullYear()} MILY'S Gourmet. Tous droits réservés.
              Abidjan, Côte d'Ivoire.
            </p>
          </div>
        </div>
      </footer>
    </div>
  )
}

import { Building2, Users, ShoppingCart, TrendingUp, ArrowRight } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const stats = [
  { title: "Entreprises actives", value: "12", icon: Building2, trend: "+2 ce mois", color: "text-blue-600" },
  { title: "Employés actifs", value: "348", icon: Users, trend: "+15 cette semaine", color: "text-green-600" },
  { title: "Commandes aujourd'hui", value: "127", icon: ShoppingCart, trend: "8h - 14h", color: "text-orange-600" },
  { title: "CA du mois", value: (2_850_000).toLocaleString("fr-CI") + " FCFA", icon: TrendingUp, trend: "+12% vs mois dernier", color: "text-purple-600" },
]

const recentOrders = [
  { ref: "CMD-2024-001", employee: "Kouamé Yves", company: "Société Générale CI", status: "Livrée", amount: 3500 },
  { ref: "CMD-2024-002", employee: "Bah Mariama", company: "MTN Cameroun", status: "En préparation", amount: 2800 },
  { ref: "CMD-2024-003", employee: "Nguema Paul", company: "Orange CI", status: "En attente", amount: 4200 },
  { ref: "CMD-2024-004", employee: "Kone Fatou", company: "UBA Bank", status: "Livrée", amount: 3500 },
]

const statusColors: Record<string, string> = {
  "Livrée": "bg-green-100 text-green-700",
  "En préparation": "bg-blue-100 text-blue-700",
  "En attente": "bg-yellow-100 text-yellow-700",
}

const quickLinks = [
  { label: "Gérer les menus", href: "/app/admin/menus" },
  { label: "Voir les commandes", href: "/app/admin/orders" },
  { label: "Générer une facture", href: "/app/admin/invoices" },
  { label: "Stock cuisine", href: "/app/kitchen/stock" },
]

export function AdminDashboard() {
  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Tableau de bord</h1>
        <p className="text-slate-500 text-sm mt-1">Vue d'ensemble de l'activité MILY'S</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardContent className="pt-6">
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-sm text-slate-500">{stat.title}</p>
                  <p className="text-2xl font-bold text-slate-900 mt-1">{stat.value}</p>
                  <p className="text-xs text-slate-400 mt-1">{stat.trend}</p>
                </div>
                <div className={`p-2 rounded-lg bg-slate-50 ${stat.color}`}>
                  <stat.icon className="h-5 w-5" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle className="text-base">Commandes récentes</CardTitle>
          </CardHeader>
          <CardContent>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-slate-500 border-b">
                  <th className="pb-2 font-medium">Référence</th>
                  <th className="pb-2 font-medium">Employé</th>
                  <th className="pb-2 font-medium">Statut</th>
                  <th className="pb-2 font-medium text-right">Montant</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {recentOrders.map((order) => (
                  <tr key={order.ref} className="py-2">
                    <td className="py-2 font-mono text-xs text-slate-600">{order.ref}</td>
                    <td className="py-2">
                      <div className="font-medium text-slate-800">{order.employee}</div>
                      <div className="text-xs text-slate-400">{order.company}</div>
                    </td>
                    <td className="py-2">
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusColors[order.status]}`}>
                        {order.status}
                      </span>
                    </td>
                    <td className="py-2 text-right font-medium text-slate-800">
                      {order.amount.toLocaleString("fr-CI")} FCFA
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Accès rapides</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {quickLinks.map((link) => (
              <Button key={link.label} variant="ghost" className="w-full justify-between text-sm" asChild>
                <a href={link.href}>
                  {link.label}
                  <ArrowRight className="h-4 w-4 text-slate-400" />
                </a>
              </Button>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

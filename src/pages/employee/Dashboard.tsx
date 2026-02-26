import { Utensils, ShoppingBag, Clock, ArrowRight, CheckCircle2 } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const todayMenu = {
  morning: { dishes: ["Beignets Haricots", "Jus de Gingembre"], price: 1000 },
  noon: { dishes: ["Poulet DG", "Attiéké", "Eau minérale"], price: 3500 },
}

const recentOrders = [
  { ref: "CMD-2026-039", date: "25/02/2026", meal: "Ndolé + Riz", status: "Livrée", amount: 3500 },
  { ref: "CMD-2026-031", date: "24/02/2026", meal: "Poulet DG + Frites", status: "Livrée", amount: 4500 },
  { ref: "CMD-2026-022", date: "21/02/2026", meal: "Attiéké Poisson", status: "Livrée", amount: 2500 },
]

export function EmployeeDashboard() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Bonjour, Kouamé Yves</h1>
          <p className="text-slate-500 text-sm mt-1">Jeudi 26 février 2026 — Bon appétit !</p>
        </div>
        <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100 text-sm px-3 py-1">
          Société Générale CI
        </Badge>
      </div>

      <Card className="bg-gradient-to-r from-orange-50 to-amber-50 border-orange-200">
        <CardContent className="pt-6">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-orange-500 rounded-lg">
              <Utensils className="h-5 w-5 text-white" />
            </div>
            <div>
              <h2 className="font-semibold text-slate-900">Menu du jour</h2>
              <p className="text-xs text-slate-500">Commandez avant 10h30 pour le déjeuner</p>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white rounded-lg p-3 border border-orange-100">
              <div className="flex justify-between items-center mb-2">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Matin</p>
                <span className="text-xs font-bold text-amber-600">{(1000).toLocaleString("fr-CI")} FCFA</span>
              </div>
              <ul className="space-y-1">
                {todayMenu.morning.dishes.map((d) => (
                  <li key={d} className="text-sm text-slate-700 flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-orange-400 shrink-0" />
                    {d}
                  </li>
                ))}
              </ul>
            </div>
            <div className="bg-white rounded-lg p-3 border border-green-100">
              <div className="flex justify-between items-center mb-2">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Midi</p>
                <span className="text-xs font-bold text-green-600">{(3500).toLocaleString("fr-CI")} FCFA</span>
              </div>
              <ul className="space-y-1">
                {todayMenu.noon.dishes.map((d) => (
                  <li key={d} className="text-sm text-slate-700 flex items-center gap-1.5">
                    <span className="h-1.5 w-1.5 rounded-full bg-green-400 shrink-0" />
                    {d}
                  </li>
                ))}
              </ul>
            </div>
          </div>
          <Button className="mt-4 w-full bg-orange-500 hover:bg-orange-600 text-white gap-2">
            <ShoppingBag className="h-4 w-4" />
            Commander maintenant
          </Button>
        </CardContent>
      </Card>

      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Commandes ce mois</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">18</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Total dépensé</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{(54_500).toLocaleString("fr-CI")} F</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Commande en cours</p>
            <p className="text-2xl font-bold text-orange-500 mt-1">Aucune</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Commandes récentes</CardTitle>
            <Button variant="ghost" size="sm" className="text-orange-500 gap-1">
              Voir tout <ArrowRight className="h-3 w-3" />
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-slate-100">
            {recentOrders.map((order) => (
              <div key={order.ref} className="flex items-center gap-3 px-4 py-3">
                <CheckCircle2 className="h-5 w-5 text-green-500 shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-slate-900 text-sm">{order.meal}</p>
                  <p className="text-xs text-slate-400 flex items-center gap-1">
                    <Clock className="h-3 w-3" />{order.date}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium text-slate-800">{order.amount.toLocaleString("fr-CI")} F</p>
                  <span className="text-xs text-green-600 font-medium">{order.status}</span>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

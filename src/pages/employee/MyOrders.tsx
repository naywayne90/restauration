import type { ElementType } from "react"
import { Search, Clock, CheckCircle2, Package, XCircle } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

const orders = [
  {
    ref: "CMD-2026-041",
    date: "26/02/2026",
    slot: "Midi",
    dishes: ["Poulet DG", "Attiéké", "Eau minérale"],
    status: "En livraison",
    amount: 4500,
  },
  {
    ref: "CMD-2026-039",
    date: "25/02/2026",
    slot: "Midi",
    dishes: ["Ndolé", "Riz blanc", "Jus d'ananas"],
    status: "Livrée",
    amount: 3500,
  },
  {
    ref: "CMD-2026-038",
    date: "25/02/2026",
    slot: "Matin",
    dishes: ["Beignets Haricots", "Jus de Gingembre"],
    status: "Livrée",
    amount: 1000,
  },
  {
    ref: "CMD-2026-031",
    date: "24/02/2026",
    slot: "Midi",
    dishes: ["Poulet DG", "Frites", "Coca-Cola"],
    status: "Livrée",
    amount: 4500,
  },
  {
    ref: "CMD-2026-022",
    date: "21/02/2026",
    slot: "Midi",
    dishes: ["Attiéké Poisson", "Salade"],
    status: "Annulée",
    amount: 2500,
  },
]

const statusConfig: Record<string, { style: string; icon: ElementType }> = {
  "Livrée": { style: "bg-green-100 text-green-700", icon: CheckCircle2 },
  "En livraison": { style: "bg-blue-100 text-blue-700", icon: Package },
  "En préparation": { style: "bg-yellow-100 text-yellow-700", icon: Clock },
  "En attente": { style: "bg-slate-100 text-slate-600", icon: Clock },
  "Annulée": { style: "bg-red-100 text-red-700", icon: XCircle },
}

export function MyOrders() {
  const totalSpent = orders.filter((o) => o.status === "Livrée").reduce((acc, o) => acc + o.amount, 0)

  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mes commandes</h1>
        <p className="text-slate-500 text-sm mt-1">Historique de vos commandes MILY'S</p>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Total commandes</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{orders.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Total dépensé (Fév)</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{totalSpent.toLocaleString("fr-CI")} F</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">En cours</p>
            <p className="text-2xl font-bold text-blue-500 mt-1">
              {orders.filter((o) => o.status === "En livraison").length}
            </p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px] max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="Référence..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous</SelectItem>
                <SelectItem value="delivered">Livrée</SelectItem>
                <SelectItem value="delivering">En livraison</SelectItem>
                <SelectItem value="cancelled">Annulée</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <div className="divide-y divide-slate-100">
            {orders.map((order) => {
              const { style, icon: StatusIcon } = statusConfig[order.status]
              return (
                <div key={order.ref} className="flex items-center gap-4 px-4 py-4">
                  <div className="shrink-0">
                    <StatusIcon className={`h-5 w-5 ${order.status === "Livrée" ? "text-green-500" : order.status === "Annulée" ? "text-red-500" : "text-blue-500"}`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="font-mono text-xs text-slate-500">{order.ref}</span>
                      <Badge variant="outline" className="text-xs">{order.slot}</Badge>
                    </div>
                    <p className="text-sm text-slate-700 truncate">
                      {order.dishes.join(" · ")}
                    </p>
                    <p className="text-xs text-slate-400 flex items-center gap-1 mt-0.5">
                      <Clock className="h-3 w-3" />{order.date}
                    </p>
                  </div>
                  <div className="text-right shrink-0 space-y-1">
                    <p className="font-semibold text-slate-900">{order.amount.toLocaleString("fr-CI")} FCFA</p>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${style}`}>
                      {order.status}
                    </span>
                  </div>
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

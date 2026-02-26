import type { ElementType } from "react"
import { ChefHat, CheckCircle2, Clock, AlertCircle } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const batches = [
  { id: 1, dish: "Ndolé", category: "Plat principal", planned: 80, produced: 80, status: "Terminé", startTime: "06:00", endTime: "07:45" },
  { id: 2, dish: "Poulet DG", category: "Plat principal", planned: 60, produced: 45, status: "En cours", startTime: "07:00", endTime: "—" },
  { id: 3, dish: "Attiéké Poisson", category: "Plat principal", planned: 50, produced: 50, status: "Terminé", startTime: "06:30", endTime: "08:00" },
  { id: 4, dish: "Beignets Haricots", category: "Entrée", planned: 120, produced: 120, status: "Terminé", startTime: "05:30", endTime: "06:45" },
  { id: 5, dish: "Jus de Gingembre", category: "Boisson", planned: 100, produced: 30, status: "En cours", startTime: "08:00", endTime: "—" },
  { id: 6, dish: "Sauce Gombo", category: "Accompagnement", planned: 40, produced: 0, status: "En attente", startTime: "—", endTime: "—" },
]

const statusStyle: Record<string, { badge: string; icon: ElementType }> = {
  "Terminé": { badge: "bg-green-100 text-green-700", icon: CheckCircle2 },
  "En cours": { badge: "bg-blue-100 text-blue-700", icon: Clock },
  "En attente": { badge: "bg-slate-100 text-slate-600", icon: AlertCircle },
}

export function DailyProduction() {
  const totalPlanned = batches.reduce((acc, b) => acc + b.planned, 0)
  const totalProduced = batches.reduce((acc, b) => acc + b.produced, 0)

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Production du jour</h1>
          <p className="text-slate-500 text-sm mt-1">Jeudi 26 février 2026 — Suivi en temps réel</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <ChefHat className="h-4 w-4" />
          Démarrer une production
        </Button>
      </div>

      <div className="grid grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Total planifié</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{totalPlanned} portions</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Produit</p>
            <p className="text-2xl font-bold text-green-600 mt-1">{totalProduced} portions</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Avancement global</p>
            <p className="text-2xl font-bold text-blue-600 mt-1">
              {Math.round((totalProduced / totalPlanned) * 100)}%
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-xs text-slate-500">Lots terminés</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">
              {batches.filter((b) => b.status === "Terminé").length}/{batches.length}
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {batches.map((batch) => {
          const pct = batch.planned > 0 ? Math.round((batch.produced / batch.planned) * 100) : 0
          const { badge, icon: StatusIcon } = statusStyle[batch.status]
          return (
            <Card key={batch.id}>
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between">
                  <div>
                    <CardTitle className="text-base text-slate-900">{batch.dish}</CardTitle>
                    <p className="text-xs text-slate-400 mt-0.5">{batch.category}</p>
                  </div>
                  <span className={`text-xs px-2 py-0.5 rounded-full font-medium flex items-center gap-1 ${badge}`}>
                    <StatusIcon className="h-3 w-3" />
                    {batch.status}
                  </span>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between text-sm text-slate-600">
                  <span>{batch.produced} / {batch.planned} portions</span>
                  <span className="font-semibold">{pct}%</span>
                </div>
                <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                  <div className="h-full bg-orange-500 rounded-full transition-all" style={{ width: `${pct}%` }} />
                </div>
                <div className="flex justify-between text-xs text-slate-400 pt-1">
                  <span>Début : {batch.startTime}</span>
                  <span>Fin : {batch.endTime}</span>
                </div>
                {batch.status === "En cours" && (
                  <Button size="sm" className="w-full bg-green-600 hover:bg-green-700 text-white mt-1">
                    Marquer comme terminé
                  </Button>
                )}
                {batch.status === "En attente" && (
                  <Button size="sm" variant="outline" className="w-full mt-1">
                    Démarrer
                  </Button>
                )}
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}

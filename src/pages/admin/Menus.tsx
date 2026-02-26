import { ChevronLeft, ChevronRight, Plus } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi"]
const dates = ["24 Fév", "25 Fév", "26 Fév", "27 Fév", "28 Fév"]

const weekMenus: Record<string, { morning: string[]; noon: string[] }> = {
  Lundi: { morning: ["Beignets Haricots", "Jus de Gingembre"], noon: ["Ndolé", "Riz blanc", "Jus d'ananas"] },
  Mardi: { morning: ["Omelette", "Pain beurre"], noon: ["Poulet DG", "Attiéké", "Eau minérale"] },
  Mercredi: { morning: ["Beignets Haricots", "Café"], noon: ["Sauce Gombo", "Riz", "Plantain"] },
  Jeudi: { morning: ["Sandwich", "Jus de fruit"], noon: ["Attiéké Poisson", "Salade", "Bissap"] },
  Vendredi: { morning: ["Omelette", "Café"], noon: ["Poulet DG", "Frites", "Coca-Cola"] },
}

const slotPrices: Record<string, number> = {
  morning: 1000,
  noon: 3500,
}

export function Menus() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Menus de la semaine</h1>
          <p className="text-slate-500 text-sm mt-1">Planifiez les menus par créneau horaire</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <Plus className="h-4 w-4" />
          Nouveau menu
        </Button>
      </div>

      <div className="flex items-center gap-3">
        <Button variant="outline" size="sm"><ChevronLeft className="h-4 w-4" /></Button>
        <span className="text-sm font-medium text-slate-700">Semaine du 24 Février 2026</span>
        <Button variant="outline" size="sm"><ChevronRight className="h-4 w-4" /></Button>
      </div>

      <div className="grid grid-cols-5 gap-3">
        {days.map((day, idx) => (
          <div key={day} className="space-y-3">
            <div className="text-center">
              <p className="font-semibold text-slate-800 text-sm">{day}</p>
              <p className="text-xs text-slate-400">{dates[idx]}</p>
            </div>

            <Card className="border-orange-100">
              <CardHeader className="pb-1 pt-3 px-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-xs text-slate-500 font-medium">Matin</CardTitle>
                  <Badge className="text-xs bg-amber-100 text-amber-700 hover:bg-amber-100">
                    {slotPrices.morning.toLocaleString("fr-CI")} F
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="px-3 pb-3">
                <ul className="space-y-1">
                  {weekMenus[day].morning.map((dish) => (
                    <li key={dish} className="text-xs text-slate-600 flex items-start gap-1">
                      <span className="text-orange-400 mt-0.5">•</span>
                      {dish}
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>

            <Card className="border-green-100">
              <CardHeader className="pb-1 pt-3 px-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-xs text-slate-500 font-medium">Midi</CardTitle>
                  <Badge className="text-xs bg-green-100 text-green-700 hover:bg-green-100">
                    {slotPrices.noon.toLocaleString("fr-CI")} F
                  </Badge>
                </div>
              </CardHeader>
              <CardContent className="px-3 pb-3">
                <ul className="space-y-1">
                  {weekMenus[day].noon.map((dish) => (
                    <li key={dish} className="text-xs text-slate-600 flex items-start gap-1">
                      <span className="text-green-400 mt-0.5">•</span>
                      {dish}
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          </div>
        ))}
      </div>
    </div>
  )
}

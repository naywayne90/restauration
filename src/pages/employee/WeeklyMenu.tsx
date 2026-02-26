import { ShoppingBag, ChevronLeft, ChevronRight } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"

const days = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi"]
const dates = ["24 Fév", "25 Fév", "26 Fév", "27 Fév", "28 Fév"]
const todayIndex = 2

const weekMenus: Record<string, { morning: { dishes: string[]; price: number }; noon: { dishes: string[]; price: number } }> = {
  Lundi: {
    morning: { dishes: ["Beignets Haricots", "Jus de Gingembre"], price: 1000 },
    noon: { dishes: ["Ndolé", "Riz blanc", "Jus d'ananas"], price: 3500 },
  },
  Mardi: {
    morning: { dishes: ["Omelette", "Pain beurre", "Café"], price: 1000 },
    noon: { dishes: ["Poulet DG", "Attiéké", "Eau minérale"], price: 4500 },
  },
  Mercredi: {
    morning: { dishes: ["Beignets Haricots", "Café"], price: 1000 },
    noon: { dishes: ["Sauce Gombo", "Riz", "Plantain"], price: 3000 },
  },
  Jeudi: {
    morning: { dishes: ["Sandwich", "Jus de fruit"], price: 1000 },
    noon: { dishes: ["Attiéké Poisson", "Salade", "Bissap"], price: 2500 },
  },
  Vendredi: {
    morning: { dishes: ["Omelette", "Pain", "Café"], price: 1000 },
    noon: { dishes: ["Poulet DG", "Frites", "Coca-Cola"], price: 4500 },
  },
}

export function WeeklyMenu() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Menu de la semaine</h1>
          <p className="text-slate-500 text-sm mt-1">Semaine du 24 au 28 février 2026</p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm"><ChevronLeft className="h-4 w-4" /></Button>
          <span className="text-sm text-slate-600 font-medium">Fév 2026</span>
          <Button variant="outline" size="sm"><ChevronRight className="h-4 w-4" /></Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
        {days.map((day, idx) => {
          const menu = weekMenus[day]
          const isToday = idx === todayIndex
          return (
            <div key={day} className={`space-y-3 ${isToday ? "relative" : ""}`}>
              <div className={`text-center py-2 rounded-lg ${isToday ? "bg-orange-500" : "bg-slate-100"}`}>
                <p className={`font-semibold text-sm ${isToday ? "text-white" : "text-slate-700"}`}>{day}</p>
                <p className={`text-xs ${isToday ? "text-orange-100" : "text-slate-400"}`}>{dates[idx]}</p>
                {isToday && (
                  <span className="text-xs text-orange-100 font-medium">Aujourd'hui</span>
                )}
              </div>

              <Card className={isToday ? "border-orange-300 shadow-md" : ""}>
                <CardHeader className="pb-2 pt-3 px-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-xs text-slate-500 font-medium">Matin</CardTitle>
                    <Badge className="bg-amber-100 text-amber-700 hover:bg-amber-100 text-xs">
                      {menu.morning.price.toLocaleString("fr-CI")} F
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="px-3 pb-3 space-y-2">
                  <ul className="space-y-1">
                    {menu.morning.dishes.map((d) => (
                      <li key={d} className="text-xs text-slate-600 flex items-center gap-1">
                        <span className="h-1 w-1 rounded-full bg-amber-400 shrink-0" />
                        {d}
                      </li>
                    ))}
                  </ul>
                  <Button size="sm" variant={isToday ? "default" : "outline"}
                    className={`w-full text-xs h-7 gap-1 ${isToday ? "bg-orange-500 hover:bg-orange-600 text-white" : ""}`}>
                    <ShoppingBag className="h-3 w-3" />
                    Commander
                  </Button>
                </CardContent>
              </Card>

              <Card className={isToday ? "border-orange-300 shadow-md" : ""}>
                <CardHeader className="pb-2 pt-3 px-3">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-xs text-slate-500 font-medium">Midi</CardTitle>
                    <Badge className="bg-green-100 text-green-700 hover:bg-green-100 text-xs">
                      {menu.noon.price.toLocaleString("fr-CI")} F
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent className="px-3 pb-3 space-y-2">
                  <ul className="space-y-1">
                    {menu.noon.dishes.map((d) => (
                      <li key={d} className="text-xs text-slate-600 flex items-center gap-1">
                        <span className="h-1 w-1 rounded-full bg-green-400 shrink-0" />
                        {d}
                      </li>
                    ))}
                  </ul>
                  <Button size="sm" variant={isToday ? "default" : "outline"}
                    className={`w-full text-xs h-7 gap-1 ${isToday ? "bg-orange-500 hover:bg-orange-600 text-white" : ""}`}>
                    <ShoppingBag className="h-3 w-3" />
                    Commander
                  </Button>
                </CardContent>
              </Card>
            </div>
          )
        })}
      </div>
    </div>
  )
}

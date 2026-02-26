import { AlertTriangle, CheckCircle2, XCircle, PackageSearch } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table"

const INGREDIENTS = [
  { name: "Huile de palme", unit: "L", current: 2.5, min: 10, status: "critical" },
  { name: "Tomates", unit: "kg", current: 5, min: 8, status: "alert" },
  { name: "Piment rouge", unit: "kg", current: 1.2, min: 3, status: "critical" },
  { name: "Poulet entier", unit: "kg", current: 25, min: 15, status: "ok" },
  { name: "Ignames", unit: "kg", current: 30, min: 20, status: "ok" },
  { name: "Graine de palme", unit: "kg", current: 8, min: 5, status: "ok" },
  { name: "Sel", unit: "kg", current: 0.5, min: 2, status: "alert" },
  { name: "Riz importé", unit: "kg", current: 45, min: 30, status: "ok" },
  { name: "Banane plantain", unit: "kg", current: 3, min: 10, status: "critical" },
  { name: "Poisson tilapia", unit: "kg", current: 12, min: 10, status: "ok" },
]

const STATUS = {
  ok: { label: "OK", icon: CheckCircle2, class: "bg-green-100 text-green-800" },
  alert: { label: "Alerte", icon: AlertTriangle, class: "bg-yellow-100 text-yellow-800" },
  critical: { label: "Critique", icon: XCircle, class: "bg-red-100 text-red-800" },
}

export function StockAlerts() {
  const critical = INGREDIENTS.filter((i) => i.status === "critical").length
  const alerts = INGREDIENTS.filter((i) => i.status === "alert").length

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Alertes stock</h2>
        <p className="text-muted-foreground">Surveillance des niveaux de stock en temps réel.</p>
      </div>

      {/* Summary */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card className="border-red-200 bg-red-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <XCircle className="h-8 w-8 text-red-600" />
              <div>
                <p className="text-2xl font-bold text-red-700">{critical}</p>
                <p className="text-sm text-red-600">Niveaux critiques</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className="border-yellow-200 bg-yellow-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <AlertTriangle className="h-8 w-8 text-yellow-600" />
              <div>
                <p className="text-2xl font-bold text-yellow-700">{alerts}</p>
                <p className="text-sm text-yellow-600">Alertes actives</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card className="border-green-200 bg-green-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <CheckCircle2 className="h-8 w-8 text-green-600" />
              <div>
                <p className="text-2xl font-bold text-green-700">
                  {INGREDIENTS.length - critical - alerts}
                </p>
                <p className="text-sm text-green-600">Niveaux normaux</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Table */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <PackageSearch className="h-5 w-5" />
            État des stocks
          </CardTitle>
          <Button variant="outline" size="sm">Commander fournitures</Button>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Ingrédient</TableHead>
                <TableHead className="text-right">Stock actuel</TableHead>
                <TableHead className="text-right">Seuil minimum</TableHead>
                <TableHead>Statut</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {INGREDIENTS.sort((a, b) => {
                const order = { critical: 0, alert: 1, ok: 2 }
                return order[a.status as keyof typeof order] - order[b.status as keyof typeof order]
              }).map((ing) => {
                const st = STATUS[ing.status as keyof typeof STATUS]
                const Icon = st.icon
                return (
                  <TableRow key={ing.name}>
                    <TableCell className="font-medium">{ing.name}</TableCell>
                    <TableCell className="text-right">
                      {ing.current} {ing.unit}
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {ing.min} {ing.unit}
                    </TableCell>
                    <TableCell>
                      <Badge className={`gap-1 ${st.class}`}>
                        <Icon className="h-3 w-3" />
                        {st.label}
                      </Badge>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}

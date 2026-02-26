import { Plus, Search, MoreHorizontal, Utensils } from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

const dishes = [
  { id: 1, name: "Poulet DG", category: "Plat principal", price: 4500, available: true, description: "Poulet Direction Générale avec plantains" },
  { id: 2, name: "Ndolé", category: "Plat principal", price: 3500, available: true, description: "Feuilles amères au bœuf et crevettes" },
  { id: 3, name: "Attiéké Poisson", category: "Plat principal", price: 2500, available: true, description: "Semoule de manioc et poisson grillé" },
  { id: 4, name: "Sauce Gombo", category: "Accompagnement", price: 1500, available: false, description: "Gombo en sauce avec du riz" },
  { id: 5, name: "Jus de Gingembre", category: "Boisson", price: 500, available: true, description: "Jus maison au gingembre frais" },
  { id: 6, name: "Beignets Haricots", category: "Entrée", price: 800, available: true, description: "Beignets de haricots à la camerounaise" },
]

const categories = ["Plat principal", "Accompagnement", "Entrée", "Dessert", "Boisson"]

export function Dishes() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Plats</h1>
          <p className="text-slate-500 text-sm mt-1">Gérez le catalogue des plats disponibles</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <Plus className="h-4 w-4" />
          Nouveau plat
        </Button>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {["Total plats", "Disponibles", "Catégories", "Prix moyen"].map((label, i) => (
          <Card key={label}>
            <CardContent className="pt-4">
              <p className="text-sm text-slate-500">{label}</p>
              <p className="text-xl font-bold text-slate-900">
                {i === 0 ? 6 : i === 1 ? 5 : i === 2 ? 4 : "2 967 FCFA"}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="Rechercher un plat..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-44">
                <SelectValue placeholder="Catégorie" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes</SelectItem>
                {categories.map((c) => (
                  <SelectItem key={c} value={c.toLowerCase()}>{c}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Plat</TableHead>
                <TableHead>Catégorie</TableHead>
                <TableHead className="text-right">Prix</TableHead>
                <TableHead className="text-center">Disponible</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {dishes.map((dish) => (
                <TableRow key={dish.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className="h-8 w-8 rounded bg-orange-50 flex items-center justify-center">
                        <Utensils className="h-4 w-4 text-orange-400" />
                      </div>
                      <div>
                        <div className="font-medium text-slate-900">{dish.name}</div>
                        <div className="text-xs text-slate-400 truncate max-w-[200px]">{dish.description}</div>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="text-xs">{dish.category}</Badge>
                  </TableCell>
                  <TableCell className="text-right font-medium text-slate-800">
                    {dish.price.toLocaleString("fr-CI")} FCFA
                  </TableCell>
                  <TableCell className="text-center">
                    <Switch defaultChecked={dish.available} />
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>Modifier</DropdownMenuItem>
                        <DropdownMenuItem>Dupliquer</DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">Supprimer</DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}

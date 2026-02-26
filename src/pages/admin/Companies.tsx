import { Search, Plus, MoreHorizontal, Building2 } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table"
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

const companies = [
  {
    id: 1,
    name: "Société Générale CI",
    city: "Abidjan",
    sector: "Finance & Banque",
    employees: 85,
    status: "Actif",
    contact: "admin@sgci.ci",
  },
  {
    id: 2,
    name: "MTN Cameroun",
    city: "Douala",
    sector: "Télécommunications",
    employees: 142,
    status: "Actif",
    contact: "rh@mtn.cm",
  },
  {
    id: 3,
    name: "Orange Côte d'Ivoire",
    city: "Abidjan",
    sector: "Télécommunications",
    employees: 67,
    status: "Suspendu",
    contact: "admin@orange.ci",
  },
]

export function Companies() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Entreprises</h1>
          <p className="text-slate-500 text-sm mt-1">Gérez les entreprises clientes de MILY'S</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <Plus className="h-4 w-4" />
          Nouvelle entreprise
        </Button>
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-4">
            <p className="text-sm text-slate-500">Total entreprises</p>
            <p className="text-2xl font-bold text-slate-900">12</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-sm text-slate-500">Actives</p>
            <p className="text-2xl font-bold text-green-600">10</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4">
            <p className="text-sm text-slate-500">Employés total</p>
            <p className="text-2xl font-bold text-slate-900">348</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center gap-3">
            <div className="relative flex-1 max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="Rechercher une entreprise..." className="pl-9" />
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Entreprise</TableHead>
                <TableHead>Ville</TableHead>
                <TableHead>Secteur</TableHead>
                <TableHead className="text-center">Employés</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {companies.map((company) => (
                <TableRow key={company.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <div className="h-8 w-8 rounded bg-orange-100 flex items-center justify-center">
                        <Building2 className="h-4 w-4 text-orange-500" />
                      </div>
                      <div>
                        <div className="font-medium text-slate-900">{company.name}</div>
                        <div className="text-xs text-slate-400">{company.contact}</div>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-slate-600">{company.city}</TableCell>
                  <TableCell className="text-slate-600">{company.sector}</TableCell>
                  <TableCell className="text-center font-medium">{company.employees}</TableCell>
                  <TableCell>
                    <Badge variant={company.status === "Actif" ? "default" : "secondary"}
                      className={company.status === "Actif" ? "bg-green-100 text-green-700 hover:bg-green-100" : ""}>
                      {company.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>Voir les détails</DropdownMenuItem>
                        <DropdownMenuItem>Modifier</DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">Suspendre</DropdownMenuItem>
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

import { Search, Plus, MoreHorizontal, SlidersHorizontal } from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"

const employees = [
  { id: 1, name: "Kouamé Yves", email: "y.kouame@sgci.ci", company: "Société Générale CI", role: "Employé", status: "Actif" },
  { id: 2, name: "Bah Mariama", email: "m.bah@mtn.cm", company: "MTN Cameroun", role: "Admin entreprise", status: "Actif" },
  { id: 3, name: "Nguema Paul", email: "p.nguema@orange.ci", company: "Orange CI", role: "Employé", status: "Inactif" },
  { id: 4, name: "Kone Fatou", email: "f.kone@uba.ci", company: "UBA Bank", role: "Employé", status: "Actif" },
  { id: 5, name: "Diallo Ibrahima", email: "i.diallo@sgci.ci", company: "Société Générale CI", role: "Caissier", status: "Actif" },
]

function initials(name: string) {
  return name.split(" ").map((n) => n[0]).join("").toUpperCase().slice(0, 2)
}

export function Employees() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Employés</h1>
          <p className="text-slate-500 text-sm mt-1">Gestion des comptes employés</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <Plus className="h-4 w-4" />
          Nouvel employé
        </Button>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px] max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="Nom, email..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-44">
                <SelectValue placeholder="Entreprise" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes les entreprises</SelectItem>
                <SelectItem value="sgci">Société Générale CI</SelectItem>
                <SelectItem value="mtn">MTN Cameroun</SelectItem>
                <SelectItem value="orange">Orange CI</SelectItem>
              </SelectContent>
            </Select>
            <Select>
              <SelectTrigger className="w-36">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous</SelectItem>
                <SelectItem value="active">Actifs</SelectItem>
                <SelectItem value="inactive">Inactifs</SelectItem>
              </SelectContent>
            </Select>
            <Button variant="outline" size="sm" className="gap-2">
              <SlidersHorizontal className="h-4 w-4" />
              Filtres
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Nom</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Entreprise</TableHead>
                <TableHead>Rôle</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {employees.map((emp) => (
                <TableRow key={emp.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Avatar className="h-8 w-8">
                        <AvatarFallback className="bg-orange-100 text-orange-600 text-xs">
                          {initials(emp.name)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="font-medium text-slate-900">{emp.name}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-slate-500 text-sm">{emp.email}</TableCell>
                  <TableCell className="text-slate-600 text-sm">{emp.company}</TableCell>
                  <TableCell>
                    <Badge variant="outline" className="text-xs">{emp.role}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge className={emp.status === "Actif" ? "bg-green-100 text-green-700 hover:bg-green-100" : "bg-slate-100 text-slate-500 hover:bg-slate-100"}>
                      {emp.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>Voir le profil</DropdownMenuItem>
                        <DropdownMenuItem>Modifier</DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">Désactiver</DropdownMenuItem>
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

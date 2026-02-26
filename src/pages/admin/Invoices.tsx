import { Search, Plus, MoreHorizontal, Download } from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"

const invoices = [
  { number: "FAC-2026-008", company: "Société Générale CI", period: "Janvier 2026", amount: 847500, status: "Payée", dueDate: "15/02/2026" },
  { number: "FAC-2026-009", company: "MTN Cameroun", period: "Janvier 2026", amount: 1_234_000, status: "Payée", dueDate: "15/02/2026" },
  { number: "FAC-2026-010", company: "Orange Côte d'Ivoire", period: "Janvier 2026", amount: 563_000, status: "En retard", dueDate: "15/02/2026" },
  { number: "FAC-2026-011", company: "UBA Bank", period: "Février 2026", amount: 920_500, status: "En attente", dueDate: "15/03/2026" },
  { number: "FAC-2026-012", company: "Société Générale CI", period: "Février 2026", amount: 891_000, status: "En attente", dueDate: "15/03/2026" },
  { number: "FAC-2026-013", company: "MTN Cameroun", period: "Février 2026", amount: 1_105_500, status: "Brouillon", dueDate: "15/03/2026" },
]

const statusStyle: Record<string, string> = {
  "Payée": "bg-green-100 text-green-700",
  "En attente": "bg-yellow-100 text-yellow-700",
  "En retard": "bg-red-100 text-red-700",
  "Brouillon": "bg-slate-100 text-slate-600",
}

export function Invoices() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Factures</h1>
          <p className="text-slate-500 text-sm mt-1">Gestion de la facturation mensuelle</p>
        </div>
        <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
          <Plus className="h-4 w-4" />
          Nouvelle facture
        </Button>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {[
          { label: "Total facturé (Fév)", value: (3_760_000).toLocaleString("fr-CI") + " FCFA", color: "text-slate-900" },
          { label: "Encaissé", value: (2_081_500).toLocaleString("fr-CI") + " FCFA", color: "text-green-600" },
          { label: "En attente", value: (1_678_500).toLocaleString("fr-CI") + " FCFA", color: "text-yellow-600" },
          { label: "En retard", value: (563_000).toLocaleString("fr-CI") + " FCFA", color: "text-red-600" },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="pt-4">
              <p className="text-xs text-slate-500">{s.label}</p>
              <p className={`text-lg font-bold mt-1 ${s.color}`}>{s.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px] max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="N° facture, entreprise..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous</SelectItem>
                <SelectItem value="paid">Payée</SelectItem>
                <SelectItem value="pending">En attente</SelectItem>
                <SelectItem value="overdue">En retard</SelectItem>
                <SelectItem value="draft">Brouillon</SelectItem>
              </SelectContent>
            </Select>
            <Select>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Période" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="feb26">Février 2026</SelectItem>
                <SelectItem value="jan26">Janvier 2026</SelectItem>
                <SelectItem value="dec25">Décembre 2025</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>N° Facture</TableHead>
                <TableHead>Entreprise</TableHead>
                <TableHead>Période</TableHead>
                <TableHead className="text-right">Montant</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead>Échéance</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {invoices.map((inv) => (
                <TableRow key={inv.number}>
                  <TableCell className="font-mono text-xs text-slate-600">{inv.number}</TableCell>
                  <TableCell className="font-medium text-slate-900">{inv.company}</TableCell>
                  <TableCell className="text-slate-500 text-sm">{inv.period}</TableCell>
                  <TableCell className="text-right font-medium text-slate-800">
                    {inv.amount.toLocaleString("fr-CI")} FCFA
                  </TableCell>
                  <TableCell>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusStyle[inv.status]}`}>
                      {inv.status}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-slate-500">{inv.dueDate}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-1">
                      <Button variant="ghost" size="sm">
                        <Download className="h-4 w-4" />
                      </Button>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>Voir la facture</DropdownMenuItem>
                          <DropdownMenuItem>Envoyer par email</DropdownMenuItem>
                          <DropdownMenuItem>Marquer comme payée</DropdownMenuItem>
                          <DropdownMenuItem className="text-red-600">Annuler</DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
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

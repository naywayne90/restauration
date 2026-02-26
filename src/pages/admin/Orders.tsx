import { Search, MoreHorizontal, FileText } from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"

const orders = [
  { ref: "CMD-2026-041", employee: "Kouamé Yves", company: "Société Générale CI", date: "26/02/2026 08:15", status: "Livrée", amount: 3500 },
  { ref: "CMD-2026-042", employee: "Bah Mariama", company: "MTN Cameroun", date: "26/02/2026 08:22", status: "En préparation", amount: 2800 },
  { ref: "CMD-2026-043", employee: "Nguema Paul", company: "Orange CI", date: "26/02/2026 08:30", status: "En attente", amount: 4200 },
  { ref: "CMD-2026-044", employee: "Kone Fatou", company: "UBA Bank", date: "26/02/2026 09:05", status: "Livrée", amount: 3500 },
  { ref: "CMD-2026-045", employee: "Diallo Ibrahima", company: "Société Générale CI", date: "26/02/2026 09:12", status: "Annulée", amount: 1500 },
  { ref: "CMD-2026-046", employee: "Traore Aminata", company: "MTN Cameroun", date: "26/02/2026 09:45", status: "En livraison", amount: 4500 },
]

const statusStyle: Record<string, string> = {
  "Livrée": "bg-green-100 text-green-700",
  "En préparation": "bg-blue-100 text-blue-700",
  "En attente": "bg-yellow-100 text-yellow-700",
  "En livraison": "bg-purple-100 text-purple-700",
  "Annulée": "bg-red-100 text-red-700",
}

export function Orders() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Commandes</h1>
          <p className="text-slate-500 text-sm mt-1">Suivi des commandes en temps réel</p>
        </div>
        <Button variant="outline" className="gap-2">
          <FileText className="h-4 w-4" />
          Exporter
        </Button>
      </div>

      <div className="grid grid-cols-5 gap-4">
        {[
          { label: "Total aujourd'hui", value: "127", color: "text-slate-900" },
          { label: "En attente", value: "18", color: "text-yellow-600" },
          { label: "En préparation", value: "34", color: "text-blue-600" },
          { label: "En livraison", value: "22", color: "text-purple-600" },
          { label: "Livrées", value: "53", color: "text-green-600" },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="pt-4">
              <p className="text-xs text-slate-500">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px] max-w-xs">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input placeholder="Référence, employé..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-44">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les statuts</SelectItem>
                <SelectItem value="pending">En attente</SelectItem>
                <SelectItem value="preparing">En préparation</SelectItem>
                <SelectItem value="delivering">En livraison</SelectItem>
                <SelectItem value="delivered">Livrée</SelectItem>
                <SelectItem value="cancelled">Annulée</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Référence</TableHead>
                <TableHead>Employé</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead className="text-right">Montant</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {orders.map((order) => (
                <TableRow key={order.ref}>
                  <TableCell className="font-mono text-xs text-slate-600">{order.ref}</TableCell>
                  <TableCell>
                    <div className="font-medium text-slate-900">{order.employee}</div>
                    <div className="text-xs text-slate-400">{order.company}</div>
                  </TableCell>
                  <TableCell className="text-sm text-slate-500">{order.date}</TableCell>
                  <TableCell>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusStyle[order.status]}`}>
                      {order.status}
                    </span>
                  </TableCell>
                  <TableCell className="text-right font-medium text-slate-800">
                    {order.amount.toLocaleString("fr-CI")} FCFA
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>Voir les détails</DropdownMenuItem>
                        <DropdownMenuItem>Changer le statut</DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">Annuler</DropdownMenuItem>
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

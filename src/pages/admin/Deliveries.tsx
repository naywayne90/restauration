import { Search, MoreHorizontal, MapPin, Truck } from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"

const deliveries = [
  { id: "LIV-001", destination: "Société Générale CI – Plateau", address: "Av. Botreau Roussel, Abidjan", driver: "Koffi Mensah", status: "Livré", scheduledTime: "08:30", actualTime: "08:25", orders: 22 },
  { id: "LIV-002", destination: "MTN Cameroun – Douala", address: "Rue Joss, Douala", driver: "Etoga Serge", status: "En cours", scheduledTime: "08:45", actualTime: "—", orders: 35 },
  { id: "LIV-003", destination: "Orange CI – Cocody", address: "Bd Latrille, Abidjan", driver: "Coulibaly Moussa", status: "En préparation", scheduledTime: "09:15", actualTime: "—", orders: 18 },
  { id: "LIV-004", destination: "UBA Bank – Marcory", address: "Av. Chardy, Abidjan", driver: "Koffi Mensah", status: "Planifié", scheduledTime: "11:30", actualTime: "—", orders: 14 },
  { id: "LIV-005", destination: "Total Energies – Bonanjo", address: "Rue du Commerce, Douala", driver: "Etoga Serge", status: "Planifié", scheduledTime: "12:00", actualTime: "—", orders: 27 },
]

const statusStyle: Record<string, string> = {
  "Livré": "bg-green-100 text-green-700",
  "En cours": "bg-blue-100 text-blue-700",
  "En préparation": "bg-yellow-100 text-yellow-700",
  "Planifié": "bg-slate-100 text-slate-600",
  "Problème": "bg-red-100 text-red-700",
}

export function Deliveries() {
  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Livraisons</h1>
          <p className="text-slate-500 text-sm mt-1">Suivi des livraisons du jour</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" className="gap-2">
            <MapPin className="h-4 w-4" />
            Voir la carte
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-4 gap-4">
        {[
          { label: "Tournées aujourd'hui", value: "8", icon: Truck, color: "text-slate-900" },
          { label: "Livrées", value: "3", color: "text-green-600" },
          { label: "En cours", value: "2", color: "text-blue-600" },
          { label: "Planifiées", value: "3", color: "text-slate-500" },
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
              <Input placeholder="Destination, livreur..." className="pl-9" />
            </div>
            <Select>
              <SelectTrigger className="w-44">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous</SelectItem>
                <SelectItem value="delivered">Livré</SelectItem>
                <SelectItem value="ongoing">En cours</SelectItem>
                <SelectItem value="preparing">En préparation</SelectItem>
                <SelectItem value="planned">Planifié</SelectItem>
              </SelectContent>
            </Select>
            <Select>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Livreur" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les livreurs</SelectItem>
                <SelectItem value="koffi">Koffi Mensah</SelectItem>
                <SelectItem value="etoga">Etoga Serge</SelectItem>
                <SelectItem value="coulibaly">Coulibaly Moussa</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID</TableHead>
                <TableHead>Destination</TableHead>
                <TableHead>Livreur</TableHead>
                <TableHead className="text-center">Commandes</TableHead>
                <TableHead>Heure prévue</TableHead>
                <TableHead>Heure réelle</TableHead>
                <TableHead>Statut</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {deliveries.map((d) => (
                <TableRow key={d.id}>
                  <TableCell className="font-mono text-xs text-slate-500">{d.id}</TableCell>
                  <TableCell>
                    <div className="font-medium text-slate-900">{d.destination}</div>
                    <div className="text-xs text-slate-400 flex items-center gap-1">
                      <MapPin className="h-3 w-3" />{d.address}
                    </div>
                  </TableCell>
                  <TableCell className="text-slate-700 text-sm">{d.driver}</TableCell>
                  <TableCell className="text-center font-medium text-slate-800">{d.orders}</TableCell>
                  <TableCell className="text-slate-600 text-sm font-medium">{d.scheduledTime}</TableCell>
                  <TableCell className="text-slate-500 text-sm">{d.actualTime}</TableCell>
                  <TableCell>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${statusStyle[d.status]}`}>
                      {d.status}
                    </span>
                  </TableCell>
                  <TableCell className="text-right">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm"><MoreHorizontal className="h-4 w-4" /></Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>Voir les détails</DropdownMenuItem>
                        <DropdownMenuItem>Changer le statut</DropdownMenuItem>
                        <DropdownMenuItem>Contacter le livreur</DropdownMenuItem>
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

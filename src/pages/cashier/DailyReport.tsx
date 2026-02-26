import { BarChart3, TrendingUp, Users, FileDown } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Table, TableBody, TableCell, TableHead, TableHeader, TableRow,
} from "@/components/ui/table"
import { formatCurrency, formatDate } from "@/lib/utils"

const COMPANY_STATS = [
  { name: "Orange Côte d'Ivoire", scans: 45, amount: 112500, percentage: 42 },
  { name: "TotalEnergies CI", scans: 38, amount: 133000, percentage: 35 },
  { name: "SGBCI", scans: 25, amount: 75000, percentage: 23 },
]

const TRANSACTIONS = [
  { ref: "SC-20260226-001", employee: "Aya Konan", company: "Orange CI", time: "08:14", amount: 2500 },
  { ref: "SC-20260226-002", employee: "Kouamé Brou", company: "TotalEnergies", time: "08:22", amount: 3500 },
  { ref: "SC-20260226-003", employee: "Mariam Diallo", company: "Orange CI", time: "08:30", amount: 2500 },
  { ref: "SC-20260226-004", employee: "Fatou Traoré", company: "TotalEnergies", time: "08:45", amount: 3000 },
  { ref: "SC-20260226-005", employee: "Yao Kouassi", company: "SGBCI", time: "09:00", amount: 3000 },
]

const totalScans = COMPANY_STATS.reduce((s, c) => s + c.scans, 0)
const totalAmount = COMPANY_STATS.reduce((s, c) => s + c.amount, 0)

export function DailyReport() {
  const today = formatDate(new Date())

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Rapport journalier</h2>
          <p className="text-muted-foreground capitalize">{today}</p>
        </div>
        <Button variant="outline" className="gap-2">
          <FileDown className="h-4 w-4" />
          Exporter PDF
        </Button>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <Users className="h-8 w-8 text-primary" />
              <div>
                <p className="text-2xl font-bold">{totalScans}</p>
                <p className="text-sm text-muted-foreground">Repas servis</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <BarChart3 className="h-8 w-8 text-green-600" />
              <div>
                <p className="text-2xl font-bold">{formatCurrency(totalAmount)}</p>
                <p className="text-sm text-muted-foreground">Chiffre d'affaires</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <TrendingUp className="h-8 w-8 text-blue-600" />
              <div>
                <p className="text-2xl font-bold">
                  {formatCurrency(Math.round(totalAmount / totalScans))}
                </p>
                <p className="text-sm text-muted-foreground">Panier moyen</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* By company */}
      <Card>
        <CardHeader>
          <CardTitle>Répartition par entreprise</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {COMPANY_STATS.map((co) => (
            <div key={co.name} className="space-y-1">
              <div className="flex justify-between text-sm">
                <span className="font-medium">{co.name}</span>
                <span className="text-muted-foreground">
                  {co.scans} repas · {formatCurrency(co.amount)}
                </span>
              </div>
              <div className="h-2 rounded-full bg-muted overflow-hidden">
                <div
                  className="h-full rounded-full bg-primary"
                  style={{ width: `${co.percentage}%` }}
                />
              </div>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Transaction list */}
      <Card>
        <CardHeader>
          <CardTitle>Dernières transactions</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Référence</TableHead>
                <TableHead>Employé</TableHead>
                <TableHead>Entreprise</TableHead>
                <TableHead>Heure</TableHead>
                <TableHead className="text-right">Montant</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {TRANSACTIONS.map((tx) => (
                <TableRow key={tx.ref}>
                  <TableCell className="font-mono text-xs">{tx.ref}</TableCell>
                  <TableCell>{tx.employee}</TableCell>
                  <TableCell>
                    <Badge variant="outline">{tx.company}</Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{tx.time}</TableCell>
                  <TableCell className="text-right font-medium">
                    {formatCurrency(tx.amount)}
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

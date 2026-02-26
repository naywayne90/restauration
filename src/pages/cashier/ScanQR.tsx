import { useState } from "react"
import { QrCode, CheckCircle2, XCircle, Clock, User } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { formatCurrency } from "@/lib/utils"

const RECENT_SCANS = [
  { name: "Aya Konan", company: "Orange CI", time: "12:14", amount: 2500, status: "success" },
  { name: "Kouamé Brou", company: "TotalEnergies", time: "12:11", amount: 3500, status: "success" },
  { name: "Mariam Diallo", company: "Orange CI", time: "12:09", amount: 2500, status: "success" },
  { name: "Jean-Paul Ahui", company: "SGCI", time: "12:05", amount: 3000, status: "error" },
  { name: "Fatou Traoré", company: "TotalEnergies", time: "11:58", amount: 2500, status: "success" },
]

export function ScanQR() {
  const [manualCode, setManualCode] = useState("")

  const totalScans = RECENT_SCANS.filter((s) => s.status === "success").length
  const totalAmount = RECENT_SCANS.filter((s) => s.status === "success")
    .reduce((sum, s) => sum + s.amount, 0)

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-2xl font-bold tracking-tight">Scanner QR Code</h2>
        <p className="text-muted-foreground">
          Scannez le QR Code d'un employé pour valider son repas.
        </p>
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-2">
        <Card className="border-green-200 bg-green-50">
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <CheckCircle2 className="h-8 w-8 text-green-600" />
              <div>
                <p className="text-2xl font-bold text-green-700">{totalScans}</p>
                <p className="text-sm text-green-600">Repas validés aujourd'hui</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <Clock className="h-8 w-8 text-primary" />
              <div>
                <p className="text-2xl font-bold">{formatCurrency(totalAmount)}</p>
                <p className="text-sm text-muted-foreground">Total journalier</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Scanner zone */}
      <Card>
        <CardHeader>
          <CardTitle>Zone de scan</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-center rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 p-12">
            <div className="text-center">
              <QrCode className="mx-auto h-20 w-20 text-primary/60 mb-4" />
              <p className="font-semibold text-gray-700">Présentez le QR Code devant la caméra</p>
              <p className="text-sm text-muted-foreground mt-1">
                Le scan se fait automatiquement
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <div className="flex-1 border-t" />
            <span className="text-xs text-muted-foreground">ou saisir manuellement</span>
            <div className="flex-1 border-t" />
          </div>

          <div className="flex gap-2">
            <Input
              placeholder="Code employé (ex: EMP-001234)"
              value={manualCode}
              onChange={(e) => setManualCode(e.target.value)}
              className="flex-1"
            />
            <Button disabled={!manualCode}>Valider</Button>
          </div>
        </CardContent>
      </Card>

      {/* Recent scans */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            Scans récents
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <ul className="divide-y">
            {RECENT_SCANS.map((scan, i) => (
              <li key={i} className="flex items-center gap-4 px-6 py-4">
                <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-muted">
                  <User className="h-5 w-5 text-muted-foreground" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-sm truncate">{scan.name}</p>
                  <p className="text-xs text-muted-foreground">{scan.company}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium">{formatCurrency(scan.amount)}</p>
                  <p className="text-xs text-muted-foreground">{scan.time}</p>
                </div>
                {scan.status === "success" ? (
                  <CheckCircle2 className="h-5 w-5 text-green-600" />
                ) : (
                  <XCircle className="h-5 w-5 text-red-500" />
                )}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}

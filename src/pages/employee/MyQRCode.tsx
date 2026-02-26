import { QrCode, Download, RefreshCw, Building2, User, Mail, Phone } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"

const employee = {
  name: "Kouamé Yves",
  code: "EMP-2026-00142",
  company: "Société Générale CI",
  department: "Direction Commerciale",
  email: "y.kouame@sgci.ci",
  phone: "+225 07 12 34 56 78",
  validUntil: "28/02/2026",
}

export function MyQRCode() {
  return (
    <div className="space-y-6 p-6 max-w-2xl">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mon QR code</h1>
        <p className="text-slate-500 text-sm mt-1">Présentez ce code à la caisse pour valider votre repas</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="border-2 border-orange-200">
          <CardContent className="pt-6 flex flex-col items-center gap-4">
            <div className="text-center">
              <p className="text-sm font-semibold text-slate-700">{employee.name}</p>
              <p className="text-xs text-slate-400">{employee.company}</p>
            </div>

            <div className="flex items-center justify-center w-48 h-48 border-2 border-dashed border-slate-300 rounded-xl bg-slate-50">
              <div className="text-center space-y-2">
                <QrCode className="h-24 w-24 text-slate-800 mx-auto" />
                <p className="text-xs font-mono text-slate-500">{employee.code}</p>
              </div>
            </div>

            <div className="text-center">
              <Badge className="bg-green-100 text-green-700 hover:bg-green-100">
                Valide jusqu'au {employee.validUntil}
              </Badge>
            </div>

            <div className="flex gap-2 w-full">
              <Button className="flex-1 bg-orange-500 hover:bg-orange-600 text-white gap-2">
                <Download className="h-4 w-4" />
                Télécharger
              </Button>
              <Button variant="outline" className="gap-2">
                <RefreshCw className="h-4 w-4" />
                Actualiser
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Informations employé</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-full bg-orange-100 flex items-center justify-center shrink-0">
                <User className="h-4 w-4 text-orange-600" />
              </div>
              <div>
                <p className="text-xs text-slate-400">Nom complet</p>
                <p className="text-sm font-medium text-slate-900">{employee.name}</p>
              </div>
            </div>
            <Separator />
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-full bg-blue-100 flex items-center justify-center shrink-0">
                <Building2 className="h-4 w-4 text-blue-600" />
              </div>
              <div>
                <p className="text-xs text-slate-400">Entreprise</p>
                <p className="text-sm font-medium text-slate-900">{employee.company}</p>
                <p className="text-xs text-slate-400">{employee.department}</p>
              </div>
            </div>
            <Separator />
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-full bg-slate-100 flex items-center justify-center shrink-0">
                <Mail className="h-4 w-4 text-slate-500" />
              </div>
              <div>
                <p className="text-xs text-slate-400">Email</p>
                <p className="text-sm font-medium text-slate-900">{employee.email}</p>
              </div>
            </div>
            <Separator />
            <div className="flex items-center gap-3">
              <div className="h-9 w-9 rounded-full bg-slate-100 flex items-center justify-center shrink-0">
                <Phone className="h-4 w-4 text-slate-500" />
              </div>
              <div>
                <p className="text-xs text-slate-400">Téléphone</p>
                <p className="text-sm font-medium text-slate-900">{employee.phone}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="bg-amber-50 border-amber-200">
        <CardContent className="pt-4 pb-4">
          <p className="text-sm text-amber-800 font-medium">Comment utiliser votre QR code ?</p>
          <ul className="mt-2 space-y-1">
            {[
              "Présentez ce QR code au point de distribution lors du service.",
              "Le caissier scannera votre code pour valider votre repas.",
              "Le montant sera débité de votre solde repas ou facturé à votre entreprise.",
            ].map((tip, i) => (
              <li key={i} className="text-xs text-amber-700 flex items-start gap-2">
                <span className="font-bold mt-0.5">{i + 1}.</span>
                {tip}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}

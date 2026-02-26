import { Save, Camera, Lock, User } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Badge } from "@/components/ui/badge"

export function Profile() {
  return (
    <div className="space-y-6 p-6 max-w-2xl">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mon profil</h1>
        <p className="text-slate-500 text-sm mt-1">Gérez vos informations personnelles</p>
      </div>

      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <div className="relative">
              <Avatar className="h-20 w-20">
                <AvatarFallback className="bg-orange-100 text-orange-600 text-2xl font-bold">KY</AvatarFallback>
              </Avatar>
              <button className="absolute bottom-0 right-0 h-7 w-7 rounded-full bg-orange-500 text-white flex items-center justify-center hover:bg-orange-600 transition-colors">
                <Camera className="h-3.5 w-3.5" />
              </button>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Kouamé Yves</h2>
              <p className="text-sm text-slate-500">y.kouame@sgci.ci</p>
              <div className="flex gap-2 mt-2">
                <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100">Employé</Badge>
                <Badge variant="outline">Société Générale CI</Badge>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <User className="h-4 w-4" />
            Informations personnelles
          </CardTitle>
          <CardDescription>Mettez à jour vos informations de contact</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Prénom</Label>
              <Input defaultValue="Yves" />
            </div>
            <div className="space-y-2">
              <Label>Nom</Label>
              <Input defaultValue="Kouamé" />
            </div>
          </div>
          <div className="space-y-2">
            <Label>Email</Label>
            <Input defaultValue="y.kouame@sgci.ci" type="email" disabled className="bg-slate-50" />
            <p className="text-xs text-slate-400">L'email ne peut pas être modifié. Contactez votre administrateur.</p>
          </div>
          <div className="space-y-2">
            <Label>Téléphone</Label>
            <Input defaultValue="+225 07 12 34 56 78" type="tel" />
          </div>
          <div className="space-y-2">
            <Label>Département</Label>
            <Select defaultValue="commercial">
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="commercial">Direction Commerciale</SelectItem>
                <SelectItem value="finance">Direction Financière</SelectItem>
                <SelectItem value="rh">Ressources Humaines</SelectItem>
                <SelectItem value="it">Direction Informatique</SelectItem>
                <SelectItem value="operations">Opérations</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
            <Save className="h-4 w-4" />
            Enregistrer les modifications
          </Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Lock className="h-4 w-4" />
            Changer le mot de passe
          </CardTitle>
          <CardDescription>Choisissez un mot de passe sécurisé d'au moins 8 caractères</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>Mot de passe actuel</Label>
            <Input type="password" placeholder="••••••••" />
          </div>
          <Separator />
          <div className="space-y-2">
            <Label>Nouveau mot de passe</Label>
            <Input type="password" placeholder="••••••••" />
          </div>
          <div className="space-y-2">
            <Label>Confirmer le nouveau mot de passe</Label>
            <Input type="password" placeholder="••••••••" />
          </div>
          <Button variant="outline" className="gap-2">
            <Lock className="h-4 w-4" />
            Mettre à jour le mot de passe
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}

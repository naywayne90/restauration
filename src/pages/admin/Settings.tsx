import { Save, Bell, Shield, Globe } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Separator } from "@/components/ui/separator"

export function Settings() {
  return (
    <div className="space-y-6 p-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Paramètres</h1>
        <p className="text-slate-500 text-sm mt-1">Configuration générale de la plateforme MILY'S</p>
      </div>

      <Tabs defaultValue="general">
        <TabsList className="mb-6">
          <TabsTrigger value="general" className="gap-2">
            <Globe className="h-4 w-4" />Général
          </TabsTrigger>
          <TabsTrigger value="notifications" className="gap-2">
            <Bell className="h-4 w-4" />Notifications
          </TabsTrigger>
          <TabsTrigger value="security" className="gap-2">
            <Shield className="h-4 w-4" />Sécurité
          </TabsTrigger>
        </TabsList>

        <TabsContent value="general" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Informations de l'application</CardTitle>
              <CardDescription>Paramètres généraux de la plateforme</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Nom de l'application</Label>
                  <Input defaultValue="MILY'S Gourmet" />
                </div>
                <div className="space-y-2">
                  <Label>Email de contact</Label>
                  <Input defaultValue="contact@milys-gourmet.ci" type="email" />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Fuseau horaire</Label>
                  <Select defaultValue="africa-abidjan">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="africa-abidjan">Africa/Abidjan (GMT+0)</SelectItem>
                      <SelectItem value="africa-douala">Africa/Douala (GMT+1)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label>Devise</Label>
                  <Select defaultValue="xof">
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="xof">FCFA (XOF)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <div className="space-y-2">
                <Label>Téléphone</Label>
                <Input defaultValue="+225 07 07 07 07 07" />
              </div>
              <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
                <Save className="h-4 w-4" />Enregistrer les modifications
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Horaires de service</CardTitle>
              <CardDescription>Créneaux de commande et de livraison</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label>Heure limite – Petit-déjeuner</Label>
                  <Input defaultValue="07:30" type="time" />
                </div>
                <div className="space-y-2">
                  <Label>Heure limite – Déjeuner</Label>
                  <Input defaultValue="10:30" type="time" />
                </div>
              </div>
              <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2">
                <Save className="h-4 w-4" />Enregistrer
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Notifications email</CardTitle>
              <CardDescription>Choisissez les événements qui déclenchent des emails</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {[
                { label: "Nouvelle commande reçue", desc: "Email à chaque nouvelle commande validée" },
                { label: "Livraison confirmée", desc: "Email quand une livraison est marquée comme effectuée" },
                { label: "Facture générée", desc: "Email automatique lors de la génération d'une facture" },
                { label: "Stock en alerte", desc: "Email quand un ingrédient passe sous le seuil minimum" },
                { label: "Rapport journalier", desc: "Résumé quotidien envoyé à 18h" },
              ].map((item, i) => (
                <div key={item.label}>
                  <div className="flex items-center justify-between py-2">
                    <div>
                      <p className="text-sm font-medium text-slate-800">{item.label}</p>
                      <p className="text-xs text-slate-400">{item.desc}</p>
                    </div>
                    <Switch defaultChecked={i < 3} />
                  </div>
                  {i < 4 && <Separator />}
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Politique de mot de passe</CardTitle>
              <CardDescription>Règles appliquées à tous les utilisateurs</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-3">
                {[
                  { label: "Longueur minimale : 8 caractères", active: true },
                  { label: "Au moins une majuscule", active: true },
                  { label: "Au moins un chiffre", active: true },
                  { label: "Au moins un caractère spécial", active: false },
                  { label: "Expiration tous les 90 jours", active: false },
                ].map((rule) => (
                  <div key={rule.label} className="flex items-center justify-between">
                    <Label className="text-sm font-normal text-slate-700">{rule.label}</Label>
                    <Switch defaultChecked={rule.active} />
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Sessions actives</CardTitle>
              <CardDescription>Gérez les sessions utilisateurs en cours</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-slate-500 mb-4">3 sessions actives en ce moment.</p>
              <Button variant="destructive" size="sm">Révoquer toutes les sessions</Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

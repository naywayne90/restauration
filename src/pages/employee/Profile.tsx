import { Save, Camera, Lock, User, Building2, LogOut, Shield, Bell } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Checkbox } from "@/components/ui/checkbox"
import { Badge } from "@/components/ui/badge"
import { Switch } from "@/components/ui/switch"
import { useAuth } from "@/hooks/use-auth"
import { useProfile } from "@/hooks/use-profile"
import { ALLERGEN_OPTIONS, PREFERENCE_OPTIONS, CURRENCY } from "@/lib/constants"
import { TicketBalance } from "@/components/shared/TicketBalance"

export function Profile() {
  const { user } = useAuth()
  const {
    profile, initials, contract, signOut,
    phone, setPhone, allergens, preferences,
    notificationsEnabled, setNotificationsEnabled,
    newPassword, setNewPassword, confirmPassword, setConfirmPassword,
    savingProfile, savingPassword,
    handleSaveProfile, handleChangePassword, handleAvatarUpload,
    toggleAllergen, togglePreference,
  } = useProfile()

  return (
    <div className="space-y-6 p-4 md:p-6 max-w-2xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mon profil</h1>
        <p className="text-slate-500 text-sm mt-1">Gérez vos informations personnelles</p>
      </div>

      {/* Avatar & info */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center gap-4">
            <div className="relative">
              <Avatar className="h-20 w-20">
                {profile?.avatar_url && <AvatarImage src={profile.avatar_url} />}
                <AvatarFallback className="bg-orange-100 text-orange-600 text-2xl font-bold">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <label className="absolute bottom-0 right-0 h-7 w-7 rounded-full bg-orange-500 text-white flex items-center justify-center hover:bg-orange-600 transition-colors cursor-pointer hover:scale-110">
                <Camera className="h-3.5 w-3.5" />
                <input type="file" accept="image/*" className="sr-only" onChange={handleAvatarUpload} />
              </label>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">{profile?.full_name}</h2>
              <p className="text-sm text-slate-500">{profile?.email}</p>
              <div className="flex gap-2 mt-2 flex-wrap">
                <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100">
                  {profile?.employee_type === "regular" ? "Employé" :
                   profile?.employee_type === "intern" ? "Stagiaire" :
                   profile?.employee_type === "guard" ? "Agent de sécurité" : "Visiteur"}
                </Badge>
                {profile?.company && (
                  <Badge variant="outline">{profile.company.name}</Badge>
                )}
                {profile?.matricule && (
                  <Badge variant="outline" className="font-mono text-xs">{profile.matricule}</Badge>
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Contract info + ticket balance */}
      {contract && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <Building2 className="h-4 w-4 text-slate-500" />
              Contrat entreprise
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-slate-500">Prix repas standard</p>
                <p className="text-sm font-semibold text-slate-900">
                  {contract.base_meal_price.toLocaleString("fr-CI")} {CURRENCY}
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-500">Taux subvention</p>
                <p className="text-sm font-semibold text-green-600">{contract.subsidy_rate}%</p>
              </div>
              <div>
                <p className="text-xs text-slate-500">Mode de paiement</p>
                <p className="text-sm font-semibold text-slate-900">
                  {contract.payment_mode === "tickets" ? "Tickets physiques" : "Facturation"}
                </p>
              </div>
              <div>
                <p className="text-xs text-slate-500">Jours ouvrés</p>
                <p className="text-sm font-semibold text-slate-900">{contract.working_days} jours/sem</p>
              </div>
            </div>

            {contract.payment_mode === "tickets" && profile && (
              <>
                <Separator />
                <TicketBalance
                  balance={profile.ticket_balance}
                  total={contract.tickets_per_month || 24}
                />
              </>
            )}
          </CardContent>
        </Card>
      )}

      {/* Personal info form */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <User className="h-4 w-4" />
            Informations personnelles
          </CardTitle>
          <CardDescription>Mettez à jour vos informations de contact</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label>Nom complet</Label>
            <Input value={profile?.full_name || ""} disabled className="bg-slate-50" />
            <p className="text-xs text-slate-400">Contactez votre administrateur pour modifier.</p>
          </div>
          <div className="space-y-2">
            <Label>Email</Label>
            <Input value={profile?.email || ""} type="email" disabled className="bg-slate-50" />
          </div>
          <div className="space-y-2">
            <Label>Téléphone</Label>
            <Input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              type="tel"
              placeholder="+225 07 XX XX XX XX"
            />
          </div>
          {profile?.department && (
            <div className="space-y-2">
              <Label>Département</Label>
              <Input value={profile.department} disabled className="bg-slate-50" />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Notification preferences */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Bell className="h-4 w-4" />
            Notifications
          </CardTitle>
          <CardDescription>Gérez vos préférences de notification</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-900">Notifications push</p>
              <p className="text-xs text-slate-500">Recevez des alertes pour les menus, commandes et rappels</p>
            </div>
            <Switch
              checked={notificationsEnabled}
              onCheckedChange={setNotificationsEnabled}
            />
          </div>
        </CardContent>
      </Card>

      {/* Allergens & Preferences */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Shield className="h-4 w-4" />
            Allergènes et préférences
          </CardTitle>
          <CardDescription>Signalez vos restrictions alimentaires</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <p className="text-sm font-medium text-slate-700 mb-3">Allergènes</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {ALLERGEN_OPTIONS.map(a => (
                <label key={a} className="flex items-center gap-2 cursor-pointer">
                  <Checkbox
                    checked={allergens.includes(a)}
                    onCheckedChange={() => toggleAllergen(a)}
                  />
                  <span className="text-sm text-slate-700">{a}</span>
                </label>
              ))}
            </div>
          </div>

          <Separator />

          <div>
            <p className="text-sm font-medium text-slate-700 mb-3">Préférences alimentaires</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {PREFERENCE_OPTIONS.map(p => (
                <label key={p} className="flex items-center gap-2 cursor-pointer">
                  <Checkbox
                    checked={preferences.includes(p)}
                    onCheckedChange={() => togglePreference(p)}
                  />
                  <span className="text-sm text-slate-700">{p}</span>
                </label>
              ))}
            </div>
          </div>

          <Button
            className="bg-orange-500 hover:bg-orange-600 text-white gap-2 hover:scale-105 transition-all"
            onClick={handleSaveProfile}
            disabled={savingProfile}
          >
            {savingProfile ? (
              <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            Enregistrer
          </Button>
        </CardContent>
      </Card>

      {/* Password change */}
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
            <Label>Nouveau mot de passe</Label>
            <Input
              type="password"
              placeholder="********"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label>Confirmer le nouveau mot de passe</Label>
            <Input
              type="password"
              placeholder="********"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
            />
          </div>
          <Button
            variant="outline"
            className="gap-2 hover:scale-105 transition-all"
            onClick={handleChangePassword}
            disabled={savingPassword || !newPassword}
          >
            {savingPassword ? (
              <span className="animate-spin h-4 w-4 border-2 border-slate-400 border-t-transparent rounded-full" />
            ) : (
              <Lock className="h-4 w-4" />
            )}
            Mettre à jour le mot de passe
          </Button>
        </CardContent>
      </Card>

      {/* Logout */}
      <Card className="border-red-200">
        <CardContent className="pt-4 pb-4">
          <Button
            variant="outline"
            className="w-full text-red-600 border-red-200 hover:bg-red-50 gap-2 hover:scale-105 transition-all"
            onClick={signOut}
          >
            <LogOut className="h-4 w-4" />
            Se déconnecter
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}

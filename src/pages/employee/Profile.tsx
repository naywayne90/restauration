import { useState } from "react"
import { Save, Camera, Lock, User, Building2, Ticket, LogOut, Shield } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Separator } from "@/components/ui/separator"
import { Checkbox } from "@/components/ui/checkbox"
import { Badge } from "@/components/ui/badge"
import { useToast } from "@/components/ui/use-toast"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"
import { ALLERGEN_OPTIONS, PREFERENCE_OPTIONS, CURRENCY } from "@/lib/constants"
import { TicketBalance } from "@/components/shared/TicketBalance"
import type { CompanyContract } from "@/lib/types"
import { useEffect } from "react"

export function Profile() {
  const { user, signOut } = useAuth()
  const { toast } = useToast()
  const profile = user?.profile
  const [phone, setPhone] = useState(profile?.phone || "")
  const [allergens, setAllergens] = useState<string[]>(profile?.allergens || [])
  const [preferences, setPreferences] = useState<string[]>(profile?.preferences || [])
  const [currentPassword, setCurrentPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [savingProfile, setSavingProfile] = useState(false)
  const [savingPassword, setSavingPassword] = useState(false)
  const [contract, setContract] = useState<CompanyContract | null>(null)

  useEffect(() => {
    if (!profile?.company_id) return
    const fetchContract = async () => {
      const { data } = await supabase
        .from("company_contracts")
        .select("*")
        .eq("company_id", profile.company_id!)
        .eq("is_active", true)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle()
      if (data) setContract(data)
    }
    fetchContract()
  }, [profile?.company_id])

  const initials = profile?.full_name
    ?.split(" ")
    .map(n => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2) || "??"

  const handleSaveProfile = async () => {
    if (!user?.user?.id) return
    setSavingProfile(true)

    try {
      const { error } = await supabase
        .from("profiles")
        .update({
          phone,
          allergens,
          preferences,
        })
        .eq("id", user.user.id)

      if (error) throw error

      toast({ title: "Profil mis a jour", description: "Vos informations ont ete enregistrees." })
    } catch (err) {
      console.error(err)
      toast({ title: "Erreur", description: "Impossible de sauvegarder.", variant: "destructive" })
    } finally {
      setSavingProfile(false)
    }
  }

  const handleChangePassword = async () => {
    if (newPassword.length < 8) {
      toast({ title: "Erreur", description: "Le mot de passe doit faire au moins 8 caracteres.", variant: "destructive" })
      return
    }
    if (newPassword !== confirmPassword) {
      toast({ title: "Erreur", description: "Les mots de passe ne correspondent pas.", variant: "destructive" })
      return
    }

    setSavingPassword(true)
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword })
      if (error) throw error

      toast({ title: "Mot de passe modifie", description: "Votre nouveau mot de passe est actif." })
      setCurrentPassword("")
      setNewPassword("")
      setConfirmPassword("")
    } catch (err) {
      console.error(err)
      toast({ title: "Erreur", description: "Impossible de changer le mot de passe.", variant: "destructive" })
    } finally {
      setSavingPassword(false)
    }
  }

  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file || !user?.user?.id) return

    const ext = file.name.split(".").pop()
    const path = `avatars/${user.user.id}.${ext}`

    const { error: uploadError } = await supabase.storage
      .from("avatars")
      .upload(path, file, { upsert: true })

    if (uploadError) {
      toast({ title: "Erreur", description: "Impossible d'envoyer la photo.", variant: "destructive" })
      return
    }

    const { data: urlData } = supabase.storage.from("avatars").getPublicUrl(path)

    await supabase
      .from("profiles")
      .update({ avatar_url: urlData.publicUrl })
      .eq("id", user.user.id)

    toast({ title: "Photo mise a jour" })
  }

  const toggleAllergen = (a: string) => {
    setAllergens(prev => prev.includes(a) ? prev.filter(x => x !== a) : [...prev, a])
  }

  const togglePreference = (p: string) => {
    setPreferences(prev => prev.includes(p) ? prev.filter(x => x !== p) : [...prev, p])
  }

  return (
    <div className="space-y-6 p-4 md:p-6 max-w-2xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mon profil</h1>
        <p className="text-slate-500 text-sm mt-1">Gerez vos informations personnelles</p>
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
              <label className="absolute bottom-0 right-0 h-7 w-7 rounded-full bg-orange-500 text-white flex items-center justify-center hover:bg-orange-600 transition-colors cursor-pointer">
                <Camera className="h-3.5 w-3.5" />
                <input type="file" accept="image/*" className="sr-only" onChange={handleAvatarUpload} />
              </label>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">{profile?.full_name}</h2>
              <p className="text-sm text-slate-500">{profile?.email}</p>
              <div className="flex gap-2 mt-2 flex-wrap">
                <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100">
                  {profile?.employee_type === "regular" ? "Employe" :
                   profile?.employee_type === "intern" ? "Stagiaire" :
                   profile?.employee_type === "guard" ? "Agent de securite" : "Visiteur"}
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
                <p className="text-xs text-slate-500">Jours ouvres</p>
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
          <CardDescription>Mettez a jour vos informations de contact</CardDescription>
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
            <Label>Telephone</Label>
            <Input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              type="tel"
              placeholder="+225 07 XX XX XX XX"
            />
          </div>
          {profile?.department && (
            <div className="space-y-2">
              <Label>Departement</Label>
              <Input value={profile.department} disabled className="bg-slate-50" />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Allergens & Preferences */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Shield className="h-4 w-4" />
            Allergenes et preferences
          </CardTitle>
          <CardDescription>Signalez vos restrictions alimentaires</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <p className="text-sm font-medium text-slate-700 mb-3">Allergenes</p>
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
            <p className="text-sm font-medium text-slate-700 mb-3">Preferences alimentaires</p>
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
            className="bg-orange-500 hover:bg-orange-600 text-white gap-2"
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
          <CardDescription>Choisissez un mot de passe securise d'au moins 8 caracteres</CardDescription>
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
            className="gap-2"
            onClick={handleChangePassword}
            disabled={savingPassword || !newPassword}
          >
            {savingPassword ? (
              <span className="animate-spin h-4 w-4 border-2 border-slate-400 border-t-transparent rounded-full" />
            ) : (
              <Lock className="h-4 w-4" />
            )}
            Mettre a jour le mot de passe
          </Button>
        </CardContent>
      </Card>

      {/* Logout */}
      <Card className="border-red-200">
        <CardContent className="pt-4 pb-4">
          <Button
            variant="outline"
            className="w-full text-red-600 border-red-200 hover:bg-red-50 gap-2"
            onClick={signOut}
          >
            <LogOut className="h-4 w-4" />
            Se deconnecter
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}

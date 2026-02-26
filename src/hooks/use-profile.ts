import { useState, useEffect } from "react"
import { useAuth } from "./use-auth"
import { supabase } from "@/lib/supabase"
import { useToast } from "@/components/ui/use-toast"
import type { CompanyContract } from "@/lib/types"

export function useProfile() {
  const { user, signOut } = useAuth()
  const { toast } = useToast()
  const profile = user?.profile

  const [phone, setPhone] = useState(profile?.phone || "")
  const [allergens, setAllergens] = useState<string[]>(profile?.allergens || [])
  const [preferences, setPreferences] = useState<string[]>(profile?.preferences || [])
  const [notificationsEnabled, setNotificationsEnabled] = useState(true)
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [savingProfile, setSavingProfile] = useState(false)
  const [savingPassword, setSavingPassword] = useState(false)
  const [contract, setContract] = useState<CompanyContract | null>(null)

  useEffect(() => {
    if (!profile?.company_id) return
    const fetchContract = async () => {
      const { data } = await supabase.from("company_contracts").select("*")
        .eq("company_id", profile.company_id!).eq("is_active", true)
        .order("created_at", { ascending: false }).limit(1).maybeSingle()
      if (data) setContract(data)
    }
    fetchContract()
  }, [profile?.company_id])

  const initials = profile?.full_name?.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2) || "??"

  const handleSaveProfile = async () => {
    if (!user?.user?.id) return
    setSavingProfile(true)
    try {
      const { error } = await supabase.from("profiles")
        .update({ phone, allergens, preferences })
        .eq("id", user.user.id)
      if (error) throw error
      toast({ title: "Profil mis à jour", description: "Vos informations ont été enregistrées." })
    } catch (err) {
      console.error(err)
      toast({ title: "Erreur", description: "Impossible de sauvegarder.", variant: "destructive" })
    } finally {
      setSavingProfile(false)
    }
  }

  const handleChangePassword = async () => {
    if (newPassword.length < 8) {
      toast({ title: "Erreur", description: "Le mot de passe doit faire au moins 8 caractères.", variant: "destructive" })
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
      toast({ title: "Mot de passe modifié" })
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
    const { error: uploadError } = await supabase.storage.from("avatars").upload(path, file, { upsert: true })
    if (uploadError) {
      toast({ title: "Erreur", description: "Impossible d'envoyer la photo.", variant: "destructive" })
      return
    }
    const { data: urlData } = supabase.storage.from("avatars").getPublicUrl(path)
    await supabase.from("profiles").update({ avatar_url: urlData.publicUrl }).eq("id", user.user.id)
    toast({ title: "Photo mise à jour" })
  }

  const toggleAllergen = (a: string) => setAllergens(prev => prev.includes(a) ? prev.filter(x => x !== a) : [...prev, a])
  const togglePreference = (p: string) => setPreferences(prev => prev.includes(p) ? prev.filter(x => x !== p) : [...prev, p])

  return {
    profile, initials, contract, signOut,
    phone, setPhone, allergens, preferences,
    notificationsEnabled, setNotificationsEnabled,
    newPassword, setNewPassword, confirmPassword, setConfirmPassword,
    savingProfile, savingPassword,
    handleSaveProfile, handleChangePassword, handleAvatarUpload,
    toggleAllergen, togglePreference,
  }
}

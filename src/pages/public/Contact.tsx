import { useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { Loader2, CheckCircle2, Mail, Phone, MapPin } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Alert, AlertDescription } from "@/components/ui/alert"

const schema = z.object({
  company: z.string().min(2, "Nom de l'entreprise requis"),
  name: z.string().min(2, "Votre nom est requis"),
  email: z.string().email("Email invalide"),
  phone: z.string().min(8, "Numéro de téléphone invalide"),
  employees: z.string().min(1, "Sélectionnez une tranche"),
  message: z.string().optional(),
})

type FormData = z.infer<typeof schema>

const CONTACT_INFO = [
  { icon: Mail, label: "Email", value: "contact@milys-gourmet.ci" },
  { icon: Phone, label: "Téléphone", value: "+225 07 00 00 00 00" },
  { icon: MapPin, label: "Adresse", value: "Plateau, Abidjan, Côte d'Ivoire" },
]

export function Contact() {
  const [sent, setSent] = useState(false)

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({ resolver: zodResolver(schema) })

  const onSubmit = async (_data: FormData) => {
    // Simulate API call
    await new Promise((r) => setTimeout(r, 1200))
    setSent(true)
  }

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-b from-orange-50 to-white py-16">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6">
          <h1 className="text-4xl font-bold text-gray-900">Contactez-nous</h1>
          <p className="mt-4 text-lg text-gray-600">
            Notre équipe vous répond dans les 24h ouvrées.
          </p>
        </div>
      </section>

      <section className="py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="grid gap-12 lg:grid-cols-2">
            {/* Contact info */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-6">
                Discutons de votre projet
              </h2>
              <p className="text-gray-600 mb-8">
                Vous souhaitez digitaliser la restauration de votre entreprise ?
                Remplissez le formulaire et nous vous recontacterons pour une
                démonstration personnalisée.
              </p>
              <div className="space-y-4">
                {CONTACT_INFO.map((info) => (
                  <div key={info.label} className="flex items-center gap-4">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                      <info.icon className="h-5 w-5 text-primary" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">{info.label}</p>
                      <p className="font-medium text-gray-900">{info.value}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Form */}
            <div className="rounded-2xl border bg-white p-8 shadow-sm">
              {sent ? (
                <div className="flex flex-col items-center gap-4 py-8 text-center">
                  <CheckCircle2 className="h-16 w-16 text-success-600" />
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">Message envoyé !</h3>
                    <p className="mt-2 text-gray-600">
                      Merci pour votre intérêt. Notre équipe commerciale vous contactera
                      dans les prochaines 24h.
                    </p>
                  </div>
                </div>
              ) : (
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                  <div className="grid gap-4 sm:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor="company">Entreprise *</Label>
                      <Input
                        id="company"
                        placeholder="Orange Côte d'Ivoire"
                        {...register("company")}
                      />
                      {errors.company && (
                        <p className="text-xs text-destructive">{errors.company.message}</p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="name">Votre nom *</Label>
                      <Input id="name" placeholder="Aya Konan" {...register("name")} />
                      {errors.name && (
                        <p className="text-xs text-destructive">{errors.name.message}</p>
                      )}
                    </div>
                  </div>

                  <div className="grid gap-4 sm:grid-cols-2">
                    <div className="space-y-2">
                      <Label htmlFor="email">Email professionnel *</Label>
                      <Input
                        id="email"
                        type="email"
                        placeholder="aya@entreprise.ci"
                        {...register("email")}
                      />
                      {errors.email && (
                        <p className="text-xs text-destructive">{errors.email.message}</p>
                      )}
                    </div>
                    <div className="space-y-2">
                      <Label htmlFor="phone">Téléphone *</Label>
                      <Input
                        id="phone"
                        placeholder="+225 07 00 00 00 00"
                        {...register("phone")}
                      />
                      {errors.phone && (
                        <p className="text-xs text-destructive">{errors.phone.message}</p>
                      )}
                    </div>
                  </div>

                  <div className="space-y-2">
                    <Label>Nombre d'employés *</Label>
                    <Select onValueChange={(val) => setValue("employees", val)}>
                      <SelectTrigger>
                        <SelectValue placeholder="Sélectionnez une tranche" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="1-50">1 — 50 employés</SelectItem>
                        <SelectItem value="51-200">51 — 200 employés</SelectItem>
                        <SelectItem value="201-500">201 — 500 employés</SelectItem>
                        <SelectItem value="500+">Plus de 500 employés</SelectItem>
                      </SelectContent>
                    </Select>
                    {errors.employees && (
                      <p className="text-xs text-destructive">{errors.employees.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="message">Message (optionnel)</Label>
                    <Textarea
                      id="message"
                      placeholder="Décrivez votre projet ou posez vos questions..."
                      rows={4}
                      {...register("message")}
                    />
                  </div>

                  <Button type="submit" className="w-full" disabled={isSubmitting}>
                    {isSubmitting ? (
                      <>
                        <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                        Envoi en cours…
                      </>
                    ) : (
                      "Envoyer ma demande"
                    )}
                  </Button>

                  <Alert>
                    <AlertDescription className="text-xs text-muted-foreground">
                      En soumettant ce formulaire, vous acceptez d'être contacté par notre
                      équipe commerciale. Vos données ne seront jamais partagées avec des tiers.
                    </AlertDescription>
                  </Alert>
                </form>
              )}
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

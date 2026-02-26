import { useState } from "react"
import { Link, useNavigate } from "react-router-dom"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"
import { UtensilsCrossed, Eye, EyeOff, Loader2, AlertCircle, Mail, Lock } from "lucide-react"
import { useAuth } from "@/hooks/use-auth"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { APP_NAME, ROLE_HOME_ROUTES } from "@/lib/constants"

// ─── Validation schema ────────────────────────────────────────────────────────

const loginSchema = z.object({
  email: z
    .string()
    .min(1, "L'email est requis")
    .email("Format d'email invalide"),
  password: z
    .string()
    .min(1, "Le mot de passe est requis")
    .min(6, "Minimum 6 caractères"),
})

type LoginForm = z.infer<typeof loginSchema>

// ─── Component ────────────────────────────────────────────────────────────────

export function LoginPage() {
  const { signIn, user } = useAuth()
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  })

  const onSubmit = async (data: LoginForm) => {
    setError(null)
    try {
      await signIn(data.email, data.password)
      const role = user?.roles[0]
      const redirect = role ? ROLE_HOME_ROUTES[role] : "/app/employee/dashboard"
      navigate(redirect, { replace: true })
    } catch (err: unknown) {
      const message =
        err instanceof Error ? err.message : "Erreur de connexion"
      if (
        message.includes("Invalid login credentials") ||
        message.includes("invalid_credentials")
      ) {
        setError("Email ou mot de passe incorrect.")
      } else if (message.includes("Email not confirmed")) {
        setError("Veuillez confirmer votre adresse email avant de vous connecter.")
      } else {
        setError(message)
      }
    }
  }

  return (
    <div className="relative flex min-h-screen">
      {/* Left panel — food illustration (desktop only) */}
      <div className="hidden lg:flex lg:w-1/2 relative bg-gradient-to-br from-orange-500 via-orange-600 to-amber-700 overflow-hidden">
        {/* Decorative circles */}
        <div className="absolute -top-20 -left-20 h-96 w-96 rounded-full bg-white/10" />
        <div className="absolute -bottom-32 -right-32 h-[500px] w-[500px] rounded-full bg-white/5" />
        <div className="absolute top-1/4 right-10 h-40 w-40 rounded-full bg-white/10" />

        {/* Food pattern SVG */}
        <svg className="absolute inset-0 h-full w-full opacity-[0.06]" viewBox="0 0 200 200">
          <defs>
            <pattern id="food-pattern" x="0" y="0" width="50" height="50" patternUnits="userSpaceOnUse">
              <circle cx="10" cy="10" r="4" fill="currentColor" />
              <circle cx="35" cy="35" r="3" fill="currentColor" />
              <circle cx="25" cy="5" r="2" fill="currentColor" />
              <circle cx="45" cy="20" r="2.5" fill="currentColor" />
              <circle cx="5" cy="40" r="1.5" fill="currentColor" />
            </pattern>
          </defs>
          <rect width="200" height="200" fill="url(#food-pattern)" />
        </svg>

        {/* Content */}
        <div className="relative z-10 flex flex-col justify-center px-12 xl:px-20">
          <div className="mb-8">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-sm mb-6">
              <UtensilsCrossed className="h-7 w-7 text-white" />
            </div>
            <h2 className="text-4xl font-bold text-white leading-tight mb-4">
              Simplifiez la restauration de vos collaborateurs
            </h2>
            <p className="text-lg text-orange-100/80 max-w-md">
              Gestion des menus, commandes, livraisons et facturation.
              Tout en une seule plateforme.
            </p>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-6 mt-4">
            <div>
              <p className="text-3xl font-bold text-white">500+</p>
              <p className="text-sm text-orange-100/70">Repas par jour</p>
            </div>
            <div>
              <p className="text-3xl font-bold text-white">15+</p>
              <p className="text-sm text-orange-100/70">Plats au choix</p>
            </div>
            <div>
              <p className="text-3xl font-bold text-white">98%</p>
              <p className="text-sm text-orange-100/70">Satisfaction</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right panel — login form */}
      <div className="flex flex-1 flex-col items-center justify-center bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 px-4">
        {/* Background glow */}
        <div className="absolute inset-0 overflow-hidden lg:hidden">
          <div className="absolute -left-40 -top-40 h-80 w-80 rounded-full bg-primary/10 blur-3xl" />
          <div className="absolute -bottom-40 -right-40 h-80 w-80 rounded-full bg-primary/10 blur-3xl" />
        </div>

        <div className="relative w-full max-w-md">
          {/* Logo (mobile only) */}
          <div className="mb-8 flex flex-col items-center gap-3 lg:hidden">
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary shadow-lg shadow-primary/30">
              <UtensilsCrossed className="h-8 w-8 text-white" />
            </div>
            <div className="text-center">
              <h1 className="text-2xl font-bold text-white">{APP_NAME}</h1>
              <p className="text-sm text-slate-400">Restauration d'entreprise</p>
            </div>
          </div>

          {/* Card */}
          <Card className="border-slate-700 bg-slate-800/60 shadow-2xl backdrop-blur">
            <CardHeader className="space-y-1 pb-4">
              <CardTitle className="text-xl text-white">Connexion</CardTitle>
              <CardDescription className="text-slate-400">
                Entrez vos identifiants pour accéder à la plateforme
              </CardDescription>
            </CardHeader>

            <form onSubmit={handleSubmit(onSubmit)} noValidate>
              <CardContent className="space-y-4">
                {error && (
                  <Alert variant="destructive">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>{error}</AlertDescription>
                  </Alert>
                )}

                {/* Email */}
                <div className="space-y-2">
                  <Label htmlFor="email" className="text-slate-300">
                    Adresse email
                  </Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
                    <Input
                      id="email"
                      type="email"
                      placeholder="vous@entreprise.ci"
                      autoComplete="email"
                      autoFocus
                      {...register("email")}
                      className={`pl-10 border-slate-600 bg-slate-700/50 text-white placeholder:text-slate-500 focus-visible:ring-primary ${
                        errors.email ? "border-destructive" : ""
                      }`}
                    />
                  </div>
                  {errors.email && (
                    <p className="text-xs text-destructive">{errors.email.message}</p>
                  )}
                </div>

                {/* Password */}
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <Label htmlFor="password" className="text-slate-300">
                      Mot de passe
                    </Label>
                    <Link
                      to="/forgot-password"
                      className="text-xs text-primary hover:underline"
                    >
                      Mot de passe oublié ?
                    </Link>
                  </div>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" />
                    <Input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      placeholder="••••••••"
                      autoComplete="current-password"
                      {...register("password")}
                      className={`pl-10 pr-10 border-slate-600 bg-slate-700/50 text-white placeholder:text-slate-500 focus-visible:ring-primary ${
                        errors.password ? "border-destructive" : ""
                      }`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((s) => !s)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white"
                      tabIndex={-1}
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                  {errors.password && (
                    <p className="text-xs text-destructive">{errors.password.message}</p>
                  )}
                </div>
              </CardContent>

              <CardFooter className="flex flex-col gap-3 pt-2">
                <Button
                  type="submit"
                  className="w-full bg-primary hover:bg-primary/90"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      Connexion en cours…
                    </>
                  ) : (
                    "Se connecter"
                  )}
                </Button>
              </CardFooter>
            </form>
          </Card>

          {/* Back to public site */}
          <p className="mt-6 text-center text-xs text-slate-500">
            <Link to="/gourmet" className="hover:text-slate-300 transition-colors">
              ← Retour au site
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}

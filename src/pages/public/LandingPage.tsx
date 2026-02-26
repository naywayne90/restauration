import { Link } from "react-router-dom"
import {
  UtensilsCrossed, Building2, Users, Smartphone, CheckCircle2,
  ArrowRight, Star, Clock, Shield, TrendingUp,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { formatCurrency } from "@/lib/utils"

const FEATURES = [
  {
    icon: UtensilsCrossed,
    title: "Menus personnalisés",
    description:
      "Créez des menus hebdomadaires adaptés aux goûts de vos équipes avec des plats locaux ivoiriens.",
  },
  {
    icon: Smartphone,
    title: "Commande mobile",
    description:
      "Les employés commandent depuis leur smartphone, n'importe où, n'importe quand.",
  },
  {
    icon: Building2,
    title: "Multi-sites",
    description:
      "Gérez plusieurs sites d'entreprise depuis un tableau de bord centralisé.",
  },
  {
    icon: Shield,
    title: "Sécurisé",
    description:
      "Authentification par QR Code individuel pour chaque employé. Zéro fraude.",
  },
  {
    icon: TrendingUp,
    title: "Reporting avancé",
    description:
      "Suivez les dépenses, les tendances et optimisez vos budgets restauration.",
  },
  {
    icon: Clock,
    title: "Livraison ponctuelle",
    description:
      "Suivi en temps réel des livraisons avec notifications push.",
  },
]

const STATS = [
  { value: "50+", label: "Entreprises clientes" },
  { value: "5 000+", label: "Employés servis" },
  { value: "98%", label: "Taux de satisfaction" },
  { value: formatCurrency(2500000), label: "Économisé / mois" },
]

export function LandingPage() {
  return (
    <div className="overflow-hidden">
      {/* Hero */}
      <section className="relative bg-gradient-to-br from-slate-900 via-slate-800 to-orange-950 py-24 md:py-32">
        <div className="absolute inset-0">
          <div className="absolute left-1/4 top-1/4 h-64 w-64 rounded-full bg-primary/20 blur-3xl" />
          <div className="absolute right-1/4 bottom-1/4 h-64 w-64 rounded-full bg-orange-400/10 blur-3xl" />
        </div>
        <div className="relative mx-auto max-w-7xl px-4 text-center sm:px-6">
          <Badge className="mb-6 bg-primary/20 text-primary hover:bg-primary/30 text-sm px-4 py-1">
            🇨🇮 N°1 de la restauration d'entreprise en Côte d'Ivoire
          </Badge>
          <h1 className="mb-6 text-4xl font-extrabold leading-tight text-white md:text-6xl">
            La restauration d'entreprise{" "}
            <span className="text-primary">réinventée</span>
          </h1>
          <p className="mx-auto mb-8 max-w-2xl text-lg text-slate-300">
            MILY'S Gourmet simplifie la gestion des repas d'entreprise à Abidjan.
            De la commande à la livraison, tout est digitalisé et optimisé.
          </p>
          <div className="flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
            <Button size="lg" asChild className="gap-2 px-8">
              <Link to="/contact">
                Demander une démo gratuite
                <ArrowRight className="h-4 w-4" />
              </Link>
            </Button>
            <Button
              size="lg"
              variant="outline"
              asChild
              className="border-slate-600 text-white hover:bg-slate-700"
            >
              <Link to="/comment-ca-marche">Comment ça marche ?</Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="bg-primary py-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="grid grid-cols-2 gap-8 md:grid-cols-4">
            {STATS.map((stat) => (
              <div key={stat.label} className="text-center">
                <p className="text-3xl font-extrabold text-white">{stat.value}</p>
                <p className="mt-1 text-sm text-orange-100">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 bg-gray-50">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-gray-900 md:text-4xl">
              Tout ce dont vous avez besoin
            </h2>
            <p className="mt-4 text-lg text-gray-600">
              Une plateforme complète pour gérer la restauration de A à Z
            </p>
          </div>
          <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
            {FEATURES.map((feat) => (
              <div
                key={feat.title}
                className="rounded-xl border bg-white p-6 shadow-sm transition-shadow hover:shadow-md"
              >
                <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
                  <feat.icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="mb-2 text-lg font-semibold text-gray-900">
                  {feat.title}
                </h3>
                <p className="text-sm text-gray-600">{feat.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Testimonial */}
      <section className="py-20">
        <div className="mx-auto max-w-4xl px-4 sm:px-6">
          <div className="rounded-2xl bg-slate-900 p-8 text-center md:p-12">
            <div className="mb-4 flex justify-center gap-1">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star key={i} className="h-5 w-5 fill-primary text-primary" />
              ))}
            </div>
            <blockquote className="mb-6 text-lg italic text-slate-300 md:text-xl">
              "MILY'S Gourmet a transformé la gestion des repas dans notre entreprise.
              Nos 200 employés commandent en 30 secondes et les livraisons sont
              toujours à l'heure. Le ROI est immédiat."
            </blockquote>
            <div className="flex items-center justify-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-white font-bold">
                KA
              </div>
              <div className="text-left">
                <p className="font-semibold text-white">Kofi Asante</p>
                <p className="text-sm text-slate-400">DRH, TotalEnergies Côte d'Ivoire</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="bg-primary py-16">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6">
          <h2 className="mb-4 text-3xl font-bold text-white">
            Prêt à digitaliser votre restauration ?
          </h2>
          <p className="mb-8 text-orange-100">
            Rejoignez plus de 50 entreprises qui font confiance à MILY'S Gourmet
          </p>
          <div className="flex flex-col items-center gap-4 sm:flex-row sm:justify-center">
            <Button
              size="lg"
              variant="outline"
              asChild
              className="border-white bg-white text-primary hover:bg-orange-50"
            >
              <Link to="/contact">
                Démarrer gratuitement
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
          </div>
          <div className="mt-6 flex items-center justify-center gap-6 text-sm text-orange-100">
            <span className="flex items-center gap-1">
              <CheckCircle2 className="h-4 w-4" /> Démo gratuite
            </span>
            <span className="flex items-center gap-1">
              <CheckCircle2 className="h-4 w-4" /> Sans engagement
            </span>
            <span className="flex items-center gap-1">
              <CheckCircle2 className="h-4 w-4" /> Support inclus
            </span>
          </div>
        </div>
      </section>
    </div>
  )
}

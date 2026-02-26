import { Link } from "react-router-dom"
import { ArrowRight, CheckCircle2, Building2, TrendingDown, Users, Clock } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { formatCurrency } from "@/lib/utils"

const PLANS = [
  {
    name: "Forfait",
    description: "Budget journalier fixe par employé",
    price: formatCurrency(3500),
    unit: "/ repas",
    features: [
      "Budget plafonné par employé",
      "Facturation mensuelle simplifiée",
      "Rapports de consommation",
      "Support prioritaire",
    ],
    highlighted: false,
  },
  {
    name: "À la carte",
    description: "L'employé paie, l'entreprise subventionne",
    price: "Flexible",
    unit: "Taux de subvention libre",
    features: [
      "Taux de subvention paramétrable",
      "Paiement via mobile money",
      "Contrôle des dépenses en temps réel",
      "Multi-sites inclus",
    ],
    highlighted: true,
  },
  {
    name: "Mixte",
    description: "Combinaison forfait + carte",
    price: "Sur mesure",
    unit: "Devis personnalisé",
    features: [
      "Configuration hybride",
      "Règles par catégorie de personnel",
      "API d'intégration RH",
      "Account manager dédié",
    ],
    highlighted: false,
  },
]

const BENEFITS = [
  {
    icon: TrendingDown,
    title: "Réduisez les coûts",
    description: "Économisez jusqu'à 30% sur votre budget restauration grâce à la digitalisation.",
  },
  {
    icon: Users,
    title: "Fidélisez vos talents",
    description: "Un repas de qualité chaque jour augmente la satisfaction et la rétention.",
  },
  {
    icon: Clock,
    title: "Gagnez du temps",
    description: "Zéro gestion administrative. Facture unique mensuelle automatisée.",
  },
  {
    icon: Building2,
    title: "Multi-sites",
    description: "Gérez tous vos sites depuis un seul tableau de bord unifié.",
  },
]

export function ForCompanies() {
  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-b from-orange-50 to-white py-16">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6">
          <Badge className="mb-4 bg-primary/10 text-primary">Pour les entreprises</Badge>
          <h1 className="text-4xl font-bold text-gray-900 md:text-5xl">
            Offrez à vos équipes{" "}
            <span className="text-primary">les meilleurs repas</span>
          </h1>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            MILY'S Gourmet gère l'intégralité de votre politique de restauration.
            Vous choisissez la formule, nous gérons le reste.
          </p>
        </div>
      </section>

      {/* Benefits */}
      <section className="py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
            {BENEFITS.map((b) => (
              <div key={b.title} className="rounded-xl border bg-white p-6 text-center shadow-sm">
                <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
                  <b.icon className="h-6 w-6 text-primary" />
                </div>
                <h3 className="mb-2 font-semibold text-gray-900">{b.title}</h3>
                <p className="text-sm text-gray-600">{b.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="bg-gray-50 py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6">
          <div className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-gray-900">Nos formules</h2>
            <p className="mt-4 text-gray-600">Choisissez la formule adaptée à votre entreprise</p>
          </div>
          <div className="grid gap-8 md:grid-cols-3">
            {PLANS.map((plan) => (
              <div
                key={plan.name}
                className={`rounded-2xl border p-8 ${
                  plan.highlighted
                    ? "border-primary bg-primary text-white shadow-xl shadow-primary/30"
                    : "border-gray-200 bg-white"
                }`}
              >
                <h3 className={`text-xl font-bold ${plan.highlighted ? "text-white" : "text-gray-900"}`}>
                  {plan.name}
                </h3>
                <p className={`mt-1 text-sm ${plan.highlighted ? "text-orange-100" : "text-gray-500"}`}>
                  {plan.description}
                </p>
                <div className="mt-4">
                  <span className={`text-3xl font-extrabold ${plan.highlighted ? "text-white" : "text-gray-900"}`}>
                    {plan.price}
                  </span>
                  <span className={`ml-1 text-sm ${plan.highlighted ? "text-orange-100" : "text-gray-500"}`}>
                    {plan.unit}
                  </span>
                </div>
                <ul className="mt-6 space-y-3">
                  {plan.features.map((f) => (
                    <li key={f} className="flex items-start gap-2 text-sm">
                      <CheckCircle2
                        className={`mt-0.5 h-4 w-4 flex-shrink-0 ${
                          plan.highlighted ? "text-orange-200" : "text-success-600"
                        }`}
                      />
                      <span className={plan.highlighted ? "text-orange-100" : "text-gray-700"}>
                        {f}
                      </span>
                    </li>
                  ))}
                </ul>
                <Button
                  asChild
                  className={`mt-8 w-full ${
                    plan.highlighted
                      ? "bg-white text-primary hover:bg-orange-50"
                      : ""
                  }`}
                  variant={plan.highlighted ? "outline" : "default"}
                >
                  <Link to="/contact">Choisir cette formule</Link>
                </Button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16">
        <div className="mx-auto max-w-4xl px-4 text-center sm:px-6">
          <h2 className="mb-4 text-3xl font-bold text-gray-900">
            Une question ? Discutons ensemble
          </h2>
          <p className="mb-8 text-gray-600">
            Notre équipe commerciale vous accompagne pour trouver la solution idéale.
          </p>
          <Button size="lg" asChild>
            <Link to="/contact">
              Contactez notre équipe <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </section>
    </div>
  )
}

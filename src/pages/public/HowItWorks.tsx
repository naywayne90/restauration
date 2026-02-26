import { Link } from "react-router-dom"
import { ArrowRight, Building2, Smartphone, ChefHat, Truck, BarChart3 } from "lucide-react"
import { Button } from "@/components/ui/button"

const STEPS = [
  {
    icon: Building2,
    step: "01",
    title: "Inscription de l'entreprise",
    description:
      "L'entreprise s'inscrit sur MILY'S Gourmet, configure ses sites et importe la liste de ses employés.",
  },
  {
    icon: Smartphone,
    step: "02",
    title: "Commande des employés",
    description:
      "Chaque employé reçoit ses identifiants, consulte le menu de la semaine et passe sa commande depuis son téléphone.",
  },
  {
    icon: ChefHat,
    step: "03",
    title: "Préparation en cuisine",
    description:
      "Nos cuisiniers reçoivent les bons de production en temps réel et préparent les repas selon les commandes.",
  },
  {
    icon: Truck,
    step: "04",
    title: "Livraison sur site",
    description:
      "Les repas sont livrés à l'heure convenue sur le site de l'entreprise. L'employé scanne son QR Code pour retirer son repas.",
  },
  {
    icon: BarChart3,
    step: "05",
    title: "Facturation & reporting",
    description:
      "L'entreprise reçoit une facture mensuelle consolidée et accède à des rapports détaillés sur les dépenses.",
  },
]

export function HowItWorks() {
  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-b from-orange-50 to-white py-16">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6">
          <h1 className="text-4xl font-bold text-gray-900">Comment ça marche ?</h1>
          <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
            MILY'S Gourmet digitalise chaque étape de la restauration d'entreprise,
            de la commande à la livraison.
          </p>
        </div>
      </section>

      {/* Steps */}
      <section className="py-16">
        <div className="mx-auto max-w-4xl px-4 sm:px-6">
          <div className="space-y-12">
            {STEPS.map((step, idx) => (
              <div
                key={step.step}
                className={`flex gap-6 items-start ${idx % 2 === 1 ? "flex-row-reverse" : ""}`}
              >
                <div className="flex-shrink-0">
                  <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary text-white text-xl font-black">
                    {step.step}
                  </div>
                </div>
                <div className="flex-1 rounded-xl border bg-white p-6 shadow-sm">
                  <div className="mb-3 flex items-center gap-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                      <step.icon className="h-5 w-5 text-primary" />
                    </div>
                    <h3 className="text-lg font-semibold text-gray-900">{step.title}</h3>
                  </div>
                  <p className="text-gray-600">{step.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="bg-primary py-16">
        <div className="mx-auto max-w-7xl px-4 text-center sm:px-6">
          <h2 className="mb-4 text-2xl font-bold text-white">
            Prêt à simplifier votre restauration ?
          </h2>
          <Button size="lg" variant="outline" asChild className="border-white bg-white text-primary">
            <Link to="/contact">
              Demander une démo <ArrowRight className="ml-2 h-4 w-4" />
            </Link>
          </Button>
        </div>
      </section>
    </div>
  )
}

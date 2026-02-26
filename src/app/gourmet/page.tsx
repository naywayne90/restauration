import { UtensilsCrossed, Building2, Truck, Star } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import Link from "next/link";

const features = [
  {
    icon: UtensilsCrossed,
    title: "Cuisine locale",
    description: "Des plats camerounais authentiques préparés chaque jour par nos chefs.",
  },
  {
    icon: Building2,
    title: "Pour les entreprises",
    description: "Solutions de restauration adaptées aux besoins de votre entreprise.",
  },
  {
    icon: Truck,
    title: "Livraison fiable",
    description: "Livraison ponctuelle sur vos sites, chaque jour.",
  },
  {
    icon: Star,
    title: "Qualité garantie",
    description: "Ingrédients frais, hygiène irréprochable, satisfaction assurée.",
  },
];

export default function GourmetHomePage() {
  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-orange-500 to-orange-600 px-4 py-24 text-center text-white">
        <div className="mx-auto max-w-3xl">
          <h1 className="mb-6 text-4xl font-bold tracking-tight sm:text-5xl">
            La restauration d&apos;entreprise réinventée
          </h1>
          <p className="mb-8 text-lg text-orange-100">
            Des repas frais, savoureux et variés livrés chaque jour dans votre entreprise.
            Découvrez MILY&apos;S Gourmet.
          </p>
          <div className="flex justify-center gap-4">
            <Button asChild size="lg" className="bg-white text-orange-600 hover:bg-orange-50">
              <Link href="/gourmet/entreprises">Découvrir nos offres</Link>
            </Button>
            <Button asChild size="lg" variant="outline" className="border-white text-white hover:bg-white/10">
              <Link href="/gourmet/contact">Nous contacter</Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="mx-auto max-w-7xl px-4 py-20 sm:px-6 lg:px-8">
        <h2 className="mb-12 text-center text-3xl font-bold">Pourquoi MILY&apos;S ?</h2>
        <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-4">
          {features.map((feature) => (
            <Card key={feature.title}>
              <CardContent className="flex flex-col items-center gap-4 pt-6 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-orange-100">
                  <feature.icon className="h-6 w-6 text-orange-500" />
                </div>
                <h3 className="font-semibold">{feature.title}</h3>
                <p className="text-sm text-muted-foreground">{feature.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>
    </div>
  );
}

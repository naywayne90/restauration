import { ShieldAlert } from "lucide-react"
import { useNavigate } from "react-router-dom"
import { Button } from "@/components/ui/button"

export function ForbiddenPage() {
  const navigate = useNavigate()

  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4">
      <div className="flex max-w-md flex-col items-center gap-4 text-center">
        <div className="flex h-20 w-20 items-center justify-center rounded-full bg-red-100">
          <ShieldAlert className="h-10 w-10 text-red-600" />
        </div>
        <h1 className="text-3xl font-bold">403</h1>
        <p className="text-xl font-semibold text-foreground">
          Accès refusé
        </p>
        <p className="text-muted-foreground">
          Vous n&apos;avez pas les permissions nécessaires pour accéder à cette
          page. Contactez votre administrateur si vous pensez qu&apos;il
          s&apos;agit d&apos;une erreur.
        </p>
        <Button onClick={() => navigate(-1)} variant="outline">
          Retour
        </Button>
      </div>
    </div>
  )
}

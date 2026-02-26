import { cn } from "@/lib/utils"
import { Ticket } from "lucide-react"
import { Progress } from "@/components/ui/progress"

interface TicketBalanceProps {
  balance: number
  total: number
  className?: string
  compact?: boolean
}

export function TicketBalance({
  balance,
  total,
  className,
  compact = false,
}: TicketBalanceProps) {
  const percentage = total > 0 ? Math.round((balance / total) * 100) : 0
  const isLow = percentage <= 25

  if (compact) {
    return (
      <div className={cn(
        "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium",
        isLow ? "bg-red-100 text-red-700" : "bg-emerald-100 text-emerald-700",
        className
      )}>
        <Ticket className="h-3.5 w-3.5" />
        {balance}/{total} tickets
      </div>
    )
  }

  return (
    <div className={cn("space-y-2", className)}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className={cn(
            "h-8 w-8 rounded-full flex items-center justify-center",
            isLow ? "bg-red-100" : "bg-emerald-100"
          )}>
            <Ticket className={cn("h-4 w-4", isLow ? "text-red-600" : "text-emerald-600")} />
          </div>
          <div>
            <p className="text-sm font-semibold text-slate-900">Solde tickets</p>
            <p className="text-xs text-slate-500">{balance} restant(s) sur {total}</p>
          </div>
        </div>
        <span className={cn(
          "text-lg font-bold",
          isLow ? "text-red-600" : "text-emerald-600"
        )}>
          {balance}
        </span>
      </div>
      <Progress
        value={percentage}
        className={cn("h-2", isLow ? "[&>div]:bg-red-500" : "[&>div]:bg-emerald-500")}
      />
    </div>
  )
}

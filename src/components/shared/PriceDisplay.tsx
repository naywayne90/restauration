import { cn } from "@/lib/utils"
import { CURRENCY } from "@/lib/constants"

interface PriceDisplayProps {
  amount: number
  size?: "sm" | "md" | "lg"
  showCurrency?: boolean
  className?: string
  highlight?: boolean
}

export function PriceDisplay({
  amount,
  size = "md",
  showCurrency = true,
  className,
  highlight = false,
}: PriceDisplayProps) {
  const sizeClasses = {
    sm: "text-sm",
    md: "text-base",
    lg: "text-xl",
  }

  return (
    <span className={cn(
      "font-bold tabular-nums",
      sizeClasses[size],
      highlight ? "text-orange-600" : "text-slate-900",
      className
    )}>
      {amount.toLocaleString("fr-CI")}
      {showCurrency && (
        <span className="ml-1 text-[0.8em] font-medium text-slate-500">
          {CURRENCY}
        </span>
      )}
    </span>
  )
}

interface PriceSplitProps {
  total: number
  companyShare: number
  employeeShare: number
  className?: string
}

export function PriceSplit({
  total,
  companyShare,
  employeeShare,
  className,
}: PriceSplitProps) {
  return (
    <div className={cn("space-y-1", className)}>
      <div className="flex justify-between items-center">
        <span className="text-xs text-slate-500">Total</span>
        <PriceDisplay amount={total} size="sm" />
      </div>
      <div className="flex justify-between items-center">
        <span className="text-xs text-green-600">Part entreprise</span>
        <span className="text-sm font-semibold text-green-600">
          -{companyShare.toLocaleString("fr-CI")} {CURRENCY}
        </span>
      </div>
      <div className="border-t border-slate-200 pt-1 flex justify-between items-center">
        <span className="text-xs font-medium text-orange-600">Votre part</span>
        <PriceDisplay amount={employeeShare} size="sm" highlight />
      </div>
    </div>
  )
}

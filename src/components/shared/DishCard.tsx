import { cn } from "@/lib/utils"
import type { Dish } from "@/lib/types"
import { CURRENCY } from "@/lib/constants"
import { Check, Leaf } from "lucide-react"

interface DishCardProps {
  dish: Dish
  selected?: boolean
  locked?: boolean
  onSelect?: () => void
  compact?: boolean
  className?: string
}

export function DishCard({
  dish,
  selected = false,
  locked = false,
  onSelect,
  compact = false,
  className,
}: DishCardProps) {
  const isClickable = !!onSelect && !locked

  return (
    <button
      type="button"
      disabled={!isClickable}
      onClick={isClickable ? onSelect : undefined}
      className={cn(
        "relative w-full text-left rounded-xl border-2 transition-all duration-200 overflow-hidden",
        "focus:outline-none focus:ring-2 focus:ring-orange-400 focus:ring-offset-2",
        selected
          ? "border-orange-500 bg-orange-50 shadow-md"
          : "border-slate-200 bg-white hover:border-slate-300",
        locked && "opacity-60 cursor-not-allowed",
        isClickable && !selected && "hover:shadow-sm cursor-pointer",
        className
      )}
    >
      {selected && (
        <div className="absolute top-2 right-2 z-10 h-6 w-6 rounded-full bg-orange-500 flex items-center justify-center">
          <Check className="h-4 w-4 text-white" />
        </div>
      )}

      {!compact && dish.photo_url && (
        <div className="relative h-32 w-full overflow-hidden bg-slate-100">
          <img
            src={dish.photo_url}
            alt={dish.name}
            className="h-full w-full object-cover"
            loading="lazy"
          />
          {dish.is_vegetarian && (
            <span className="absolute bottom-2 left-2 flex items-center gap-1 rounded-full bg-green-600 px-2 py-0.5 text-[10px] font-medium text-white">
              <Leaf className="h-3 w-3" /> Veg
            </span>
          )}
        </div>
      )}

      <div className={cn("p-3", compact && "flex items-center gap-3")}>
        {compact && dish.photo_url && (
          <img
            src={dish.photo_url}
            alt={dish.name}
            className="h-12 w-12 rounded-lg object-cover shrink-0"
            loading="lazy"
          />
        )}
        <div className="flex-1 min-w-0">
          <p className={cn(
            "font-semibold text-slate-900 truncate",
            compact ? "text-sm" : "text-base"
          )}>
            {dish.name}
          </p>
          {dish.description && !compact && (
            <p className="text-xs text-slate-500 mt-0.5 line-clamp-2">{dish.description}</p>
          )}
        </div>
        <p className={cn(
          "font-bold text-orange-600",
          compact ? "text-sm shrink-0" : "text-sm mt-1"
        )}>
          {dish.price.toLocaleString("fr-CI")} {CURRENCY}
        </p>
      </div>
    </button>
  )
}

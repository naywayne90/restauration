import { cn } from "@/lib/utils"
import type { OrderStatus, WeeklyPlanStatus } from "@/lib/types"
import { ORDER_STATUS_CONFIG } from "@/lib/constants"
import { CheckCircle2, Clock, XCircle, UserX, FileCheck, FileLock, FileEdit } from "lucide-react"

const ORDER_ICONS = {
  confirmed: Clock,
  served: CheckCircle2,
  no_show: UserX,
  cancelled: XCircle,
} as const

const PLAN_STATUS_CONFIG: Record<WeeklyPlanStatus, { label: string; color: string }> = {
  draft: { label: "Brouillon", color: "bg-slate-100 text-slate-700" },
  confirmed: { label: "Valide", color: "bg-green-100 text-green-700" },
  locked: { label: "Verrouille", color: "bg-purple-100 text-purple-700" },
}

const PLAN_ICONS = {
  draft: FileEdit,
  confirmed: FileCheck,
  locked: FileLock,
} as const

interface OrderStatusBadgeProps {
  status: OrderStatus
  className?: string
}

export function OrderStatusBadge({ status, className }: OrderStatusBadgeProps) {
  const config = ORDER_STATUS_CONFIG[status]
  const Icon = ORDER_ICONS[status]

  return (
    <span className={cn(
      "inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium",
      config.color,
      className
    )}>
      <Icon className="h-3 w-3" />
      {config.label}
    </span>
  )
}

interface PlanStatusBadgeProps {
  status: WeeklyPlanStatus
  className?: string
}

export function PlanStatusBadge({ status, className }: PlanStatusBadgeProps) {
  const config = PLAN_STATUS_CONFIG[status]
  const Icon = PLAN_ICONS[status]

  return (
    <span className={cn(
      "inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium",
      config.color,
      className
    )}>
      <Icon className="h-3 w-3" />
      {config.label}
    </span>
  )
}

import { useEffect, useState } from "react"
import { cn } from "@/lib/utils"
import { Clock, Lock } from "lucide-react"

interface CountdownTimerProps {
  deadline: string // ISO timestamp
  className?: string
  onExpired?: () => void
  compact?: boolean
}

function getTimeRemaining(deadline: string) {
  const total = new Date(deadline).getTime() - Date.now()
  if (total <= 0) return { total: 0, days: 0, hours: 0, minutes: 0, expired: true }

  const days = Math.floor(total / (1000 * 60 * 60 * 24))
  const hours = Math.floor((total / (1000 * 60 * 60)) % 24)
  const minutes = Math.floor((total / (1000 * 60)) % 60)

  return { total, days, hours, minutes, expired: false }
}

export function CountdownTimer({
  deadline,
  className,
  onExpired,
  compact = false,
}: CountdownTimerProps) {
  const [time, setTime] = useState(() => getTimeRemaining(deadline))

  useEffect(() => {
    const interval = setInterval(() => {
      const remaining = getTimeRemaining(deadline)
      setTime(remaining)
      if (remaining.expired) {
        clearInterval(interval)
        onExpired?.()
      }
    }, 60_000) // update every minute

    return () => clearInterval(interval)
  }, [deadline, onExpired])

  if (time.expired) {
    return (
      <span className={cn(
        "inline-flex items-center gap-1 text-xs font-medium text-red-600",
        className
      )}>
        <Lock className="h-3 w-3" />
        Verrouille
      </span>
    )
  }

  const isUrgent = time.days === 0 && time.hours < 12

  if (compact) {
    return (
      <span className={cn(
        "inline-flex items-center gap-1 text-xs font-medium",
        isUrgent ? "text-red-600" : "text-slate-500",
        className
      )}>
        <Clock className="h-3 w-3" />
        {time.days > 0 ? `${time.days}j ${time.hours}h` : `${time.hours}h ${time.minutes}m`}
      </span>
    )
  }

  return (
    <div className={cn(
      "flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-medium",
      isUrgent
        ? "bg-red-50 text-red-700 border border-red-200"
        : "bg-amber-50 text-amber-700 border border-amber-200",
      className
    )}>
      <Clock className="h-3.5 w-3.5" />
      <span>
        {time.days > 0 && <>{time.days}j </>}
        {time.hours}h {time.minutes}m restant(es)
      </span>
    </div>
  )
}

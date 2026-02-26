import { cn } from "@/lib/utils"
import { DAY_SHORT_LABELS } from "@/lib/types"
import { Lock } from "lucide-react"

interface WeekDay {
  dayOfWeek: number
  date: string // YYYY-MM-DD
  label: string
  isToday: boolean
  isLocked: boolean
  hasSelection: boolean
}

interface WeekCalendarProps {
  days: WeekDay[]
  selectedDay: number
  onSelectDay: (dayOfWeek: number) => void
  className?: string
}

export function WeekCalendar({
  days,
  selectedDay,
  onSelectDay,
  className,
}: WeekCalendarProps) {
  return (
    <div className={cn("flex gap-1.5 overflow-x-auto pb-1", className)}>
      {days.map((day) => {
        const isActive = day.dayOfWeek === selectedDay
        const dateObj = new Date(day.date + "T00:00:00")
        const dayNum = dateObj.getDate()

        return (
          <button
            key={day.dayOfWeek}
            type="button"
            onClick={() => onSelectDay(day.dayOfWeek)}
            className={cn(
              "flex flex-col items-center min-w-[52px] px-2 py-2 rounded-xl transition-all duration-200",
              "focus:outline-none focus:ring-2 focus:ring-orange-400",
              isActive
                ? "bg-orange-500 text-white shadow-lg scale-105"
                : day.isToday
                ? "bg-orange-100 text-orange-700"
                : "bg-slate-100 text-slate-600 hover:bg-slate-200",
              day.isLocked && !isActive && "opacity-50"
            )}
          >
            <span className="text-[10px] font-medium uppercase">
              {DAY_SHORT_LABELS[day.dayOfWeek] || day.label}
            </span>
            <span className={cn(
              "text-lg font-bold leading-tight",
              isActive ? "text-white" : "text-slate-900"
            )}>
              {dayNum}
            </span>
            {day.isLocked ? (
              <Lock className={cn("h-3 w-3 mt-0.5", isActive ? "text-orange-200" : "text-slate-400")} />
            ) : day.hasSelection ? (
              <div className={cn(
                "h-1.5 w-1.5 rounded-full mt-0.5",
                isActive ? "bg-white" : "bg-orange-500"
              )} />
            ) : (
              <div className="h-1.5 w-1.5 mt-0.5" />
            )}
          </button>
        )
      })}
    </div>
  )
}

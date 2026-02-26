import { useMemo } from "react"
import { Link } from "react-router-dom"
import {
  Utensils, QrCode, ArrowRight, Bell, Clock,
  ShoppingBag, CalendarDays, CheckCircle2
} from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useAuth } from "@/hooks/use-auth"
import { useEmployeeDashboard } from "@/hooks/use-employee-dashboard"
import { CURRENCY } from "@/lib/constants"
import { DAY_LABELS } from "@/lib/types"
import { TicketBalance } from "@/components/shared/TicketBalance"
import { OrderStatusBadge } from "@/components/shared/StatusBadge"
import { PriceDisplay } from "@/components/shared/PriceDisplay"

export function EmployeeDashboard() {
  const { user } = useAuth()
  const {
    todayOrder, recentOrders, notifications, unreadCount,
    contract, weeklyPlan, loading, monthlySpent,
  } = useEmployeeDashboard()

  const profile = user?.profile
  const today = new Date()
  const dayOfWeek = today.getDay() || 7

  const greeting = useMemo(() => {
    const hour = today.getHours()
    if (hour < 12) return "Bonjour"
    if (hour < 18) return "Bon après-midi"
    return "Bonsoir"
  }, [])

  const firstName = profile?.full_name?.split(" ").pop() || "Employé"
  const initials = profile?.full_name?.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2) || "??"

  const weekDays = useMemo(() => {
    const startOfWeek = new Date(today)
    const diff = (today.getDay() || 7) - 1
    startOfWeek.setDate(today.getDate() - diff)

    return Array.from({ length: 5 }, (_, i) => {
      const d = new Date(startOfWeek)
      d.setDate(startOfWeek.getDate() + i)
      const dow = i + 1
      const isToday = dow === dayOfWeek
      const planItem = weeklyPlan?.items?.find(item => item.day_of_week === dow)
      const hasSelection = !!planItem && !planItem.is_cancelled
      const deadlineDate = new Date(d)
      deadlineDate.setDate(deadlineDate.getDate() - 2)
      deadlineDate.setHours(23, 59, 59, 999)
      const isLocked = !isToday && new Date() > deadlineDate

      return {
        dayOfWeek: dow,
        dayNum: d.getDate(),
        isToday,
        label: DAY_LABELS[dow],
        hasSelection,
        isLocked,
      }
    })
  }, [dayOfWeek, weeklyPlan])

  const orderState = todayOrder
    ? todayOrder.status === "served" || todayOrder.ticket_used
      ? "scanned"
      : "confirmed"
    : "none"

  if (loading) {
    return (
      <div className="space-y-6 p-4 md:p-6">
        <Skeleton className="h-16 w-full rounded-xl" />
        <Skeleton className="h-40 w-full rounded-xl" />
        <div className="grid grid-cols-5 gap-2">
          {Array.from({ length: 5 }, (_, i) => <Skeleton key={i} className="h-16 rounded-xl" />)}
        </div>
        <Skeleton className="h-48 w-full rounded-xl" />
      </div>
    )
  }

  return (
    <div className="space-y-6 p-4 md:p-6">
      {/* Greeting + Avatar + Notification bell */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <Avatar className="h-12 w-12">
            {profile?.avatar_url && <AvatarImage src={profile.avatar_url} />}
            <AvatarFallback className="bg-orange-100 text-orange-600 font-bold">
              {initials}
            </AvatarFallback>
          </Avatar>
          <div>
            <h1 className="text-xl font-bold text-slate-900">
              {greeting}, {firstName}
            </h1>
            <p className="text-slate-500 text-sm">
              {today.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long" })}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <Badge className="bg-green-100 text-green-700 hover:bg-green-100 hidden sm:flex">
            {monthlySpent.toLocaleString("fr-CI")} F ce mois
          </Badge>
          <button type="button" className="relative">
            <div className="h-9 w-9 rounded-full bg-slate-100 flex items-center justify-center hover:bg-slate-200 transition-colors">
              <Bell className="h-5 w-5 text-slate-600" />
            </div>
            {unreadCount > 0 && (
              <span className="absolute -top-1 -right-1 h-5 w-5 rounded-full bg-red-500 text-white text-[10px] font-bold flex items-center justify-center">
                {unreadCount}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* Today's order card */}
      <Card className={
        orderState === "confirmed"
          ? "bg-gradient-to-r from-green-50 to-emerald-50 border-green-200"
          : orderState === "scanned"
          ? "bg-gradient-to-r from-slate-50 to-slate-100 border-slate-300"
          : "bg-gradient-to-r from-orange-50 to-amber-50 border-orange-200"
      }>
        <CardContent className="pt-6">
          <div className="flex items-center gap-3 mb-4">
            <div className={`p-2 rounded-lg ${
              orderState === "confirmed" ? "bg-green-500"
                : orderState === "scanned" ? "bg-slate-400"
                : "bg-orange-500"
            }`}>
              <Utensils className="h-5 w-5 text-white" />
            </div>
            <div className="flex-1">
              <h2 className="font-semibold text-slate-900">
                {orderState === "confirmed" ? "Repas confirmé"
                  : orderState === "scanned" ? "Repas déjà servi"
                  : "Pas de commande aujourd'hui"}
              </h2>
              {todayOrder?.dish && (
                <p className="text-sm text-slate-600">{todayOrder.dish.name}</p>
              )}
            </div>
            {todayOrder && <OrderStatusBadge status={todayOrder.status} />}
          </div>

          {todayOrder ? (
            <div className="flex flex-col sm:flex-row gap-3">
              {todayOrder.dish?.photo_url && (
                <img
                  src={todayOrder.dish.photo_url}
                  alt={todayOrder.dish.name}
                  className="h-24 w-full sm:w-32 rounded-lg object-cover"
                />
              )}
              <div className="flex-1 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">Total</span>
                  <PriceDisplay amount={todayOrder.total_price} size="sm" />
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-green-600">Part entreprise</span>
                  <span className="text-green-600 font-medium">
                    -{todayOrder.company_share.toLocaleString("fr-CI")} {CURRENCY}
                  </span>
                </div>
                <div className="flex justify-between text-sm font-semibold border-t border-orange-200 pt-1">
                  <span className="text-orange-600">Votre part</span>
                  <span className="text-orange-600">
                    {todayOrder.employee_share.toLocaleString("fr-CI")} {CURRENCY}
                  </span>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-sm text-slate-500">
              Consultez le menu de la semaine pour planifier vos repas.
            </p>
          )}

          <div className="flex gap-2 mt-4">
            {orderState === "confirmed" && (
              <Button asChild className="flex-1 bg-green-600 hover:bg-green-700 text-white gap-2 hover:scale-105 transition-all">
                <Link to="/app/employee/qrcode">
                  <QrCode className="h-4 w-4" /> Voir mon QR code
                </Link>
              </Button>
            )}
            <Button asChild variant={todayOrder ? "outline" : "default"}
              className={!todayOrder ? "flex-1 bg-orange-500 hover:bg-orange-600 text-white gap-2 hover:scale-105 transition-all" : "gap-2 hover:scale-105 transition-all"}>
              <Link to="/app/employee/menu">
                <ShoppingBag className="h-4 w-4" />
                {todayOrder ? "Menu" : "Planifier mes repas"}
              </Link>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Week calendar strip — green=ordered, grey=not chosen, red=locked, blue=today */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {weekDays.map((day) => (
          <Link
            key={day.dayOfWeek}
            to="/app/employee/menu"
            className={`flex flex-col items-center min-w-[56px] px-2 py-2 rounded-xl transition-all duration-200 ${
              day.isToday
                ? "bg-blue-500 text-white shadow-lg"
                : day.hasSelection
                ? "bg-green-50 border border-green-300"
                : day.isLocked
                ? "bg-red-50 border border-red-200"
                : "bg-slate-100 hover:bg-slate-200"
            }`}
          >
            <span className="text-[10px] font-medium uppercase">
              {day.label.slice(0, 3)}
            </span>
            <span className={`text-lg font-bold leading-tight ${
              day.isToday ? "text-white"
                : day.hasSelection ? "text-green-800"
                : day.isLocked ? "text-red-400"
                : "text-slate-900"
            }`}>
              {day.dayNum}
            </span>
            {day.hasSelection && (
              <CheckCircle2 className={`h-3 w-3 mt-0.5 ${day.isToday ? "text-white" : "text-green-500"}`} />
            )}
          </Link>
        ))}
      </div>

      {/* Ticket balance for ticket companies */}
      {contract?.payment_mode === "tickets" && profile && (
        <Card>
          <CardContent className="pt-6">
            <TicketBalance
              balance={profile.ticket_balance}
              total={contract.tickets_per_month || 24}
            />
          </CardContent>
        </Card>
      )}

      {/* Recent orders (3) */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Commandes récentes</CardTitle>
            <Button asChild variant="ghost" size="sm" className="text-orange-500 gap-1 hover:scale-105 transition-all">
              <Link to="/app/employee/orders">
                Voir tout <ArrowRight className="h-3 w-3" />
              </Link>
            </Button>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {recentOrders.length === 0 ? (
            <p className="px-4 pb-4 text-sm text-slate-400">Aucune commande pour le moment.</p>
          ) : (
            <div className="divide-y divide-slate-100">
              {recentOrders.slice(0, 3).map((order) => (
                <div key={order.id} className="flex items-center gap-3 px-4 py-3">
                  {order.dish?.photo_url ? (
                    <img
                      src={order.dish.photo_url}
                      alt={order.dish.name}
                      className="h-10 w-10 rounded-lg object-cover shrink-0"
                    />
                  ) : (
                    <div className="h-10 w-10 rounded-lg bg-slate-100 flex items-center justify-center shrink-0">
                      <Utensils className="h-5 w-5 text-slate-400" />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-slate-900 text-sm truncate">
                      {order.dish?.name || "Plat"}
                    </p>
                    <p className="text-xs text-slate-400 flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {new Date(order.order_date).toLocaleDateString("fr-FR", { day: "numeric", month: "short" })}
                    </p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="text-sm font-medium text-slate-800">
                      {order.employee_share.toLocaleString("fr-CI")} F
                    </p>
                    <OrderStatusBadge status={order.status} className="mt-0.5" />
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Menu preview section */}
      <Card className="bg-gradient-to-r from-orange-50 to-amber-50 border-orange-200">
        <CardContent className="pt-6">
          <div className="flex items-center gap-3 mb-3">
            <CalendarDays className="h-5 w-5 text-orange-500" />
            <h3 className="font-semibold text-slate-900">Menu de la semaine</h3>
          </div>
          <p className="text-sm text-slate-600 mb-4">
            Planifiez vos repas pour la semaine et profitez de la subvention entreprise.
          </p>
          <Button asChild className="w-full bg-orange-500 hover:bg-orange-600 text-white gap-2 hover:scale-105 transition-all">
            <Link to="/app/employee/menu">
              <CalendarDays className="h-4 w-4" />
              Planifier ma semaine
            </Link>
          </Button>
        </CardContent>
      </Card>

      {/* Notifications */}
      {notifications.length > 0 && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <Bell className="h-4 w-4 text-orange-500" />
              Notifications
              <Badge className="bg-red-500 text-white hover:bg-red-500 text-xs">
                {notifications.length}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-slate-100">
              {notifications.map((notif) => (
                <div key={notif.id} className="px-4 py-3">
                  <p className="text-sm font-medium text-slate-900">{notif.title}</p>
                  <p className="text-xs text-slate-500 mt-0.5">{notif.message}</p>
                  <p className="text-[10px] text-slate-400 mt-1">
                    {new Date(notif.created_at).toLocaleDateString("fr-FR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })}
                  </p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

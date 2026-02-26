import { useEffect, useMemo, useState } from "react"
import { Link } from "react-router-dom"
import {
  Utensils, QrCode, ArrowRight, Bell, Clock,
  ShoppingBag
} from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"
import type { Order, Notification, WeeklyPlan, Dish, CompanyContract } from "@/lib/types"
import { CURRENCY } from "@/lib/constants"
import { DAY_LABELS } from "@/lib/types"
import { TicketBalance } from "@/components/shared/TicketBalance"
import { OrderStatusBadge } from "@/components/shared/StatusBadge"
import { PriceDisplay } from "@/components/shared/PriceDisplay"

export function EmployeeDashboard() {
  const { user } = useAuth()
  const [todayOrder, setTodayOrder] = useState<(Order & { dish?: Dish }) | null>(null)
  const [recentOrders, setRecentOrders] = useState<(Order & { dish?: Dish })[]>([])
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [contract, setContract] = useState<CompanyContract | null>(null)
  const [weeklyPlan, setWeeklyPlan] = useState<WeeklyPlan | null>(null)
  const [loading, setLoading] = useState(true)

  const profile = user?.profile
  const today = new Date()
  const todayStr = today.toISOString().split("T")[0]
  const dayOfWeek = today.getDay() || 7 // 1=Mon...7=Sun

  const greeting = useMemo(() => {
    const hour = today.getHours()
    if (hour < 12) return "Bonjour"
    if (hour < 18) return "Bon apres-midi"
    return "Bonsoir"
  }, [])

  const firstName = profile?.full_name?.split(" ").pop() || "Employe"

  useEffect(() => {
    if (!user?.user?.id) return

    const fetchData = async () => {
      setLoading(true)
      const userId = user.user.id

      const [orderRes, recentRes, notifRes, contractRes, planRes] = await Promise.all([
        // Today's order
        supabase
          .from("orders")
          .select("*, dish:dishes(*)")
          .eq("user_id", userId)
          .eq("order_date", todayStr)
          .maybeSingle(),
        // Recent orders
        supabase
          .from("orders")
          .select("*, dish:dishes(*)")
          .eq("user_id", userId)
          .order("order_date", { ascending: false })
          .limit(5),
        // Notifications
        supabase
          .from("notifications")
          .select("*")
          .eq("user_id", userId)
          .eq("is_read", false)
          .order("created_at", { ascending: false })
          .limit(5),
        // Contract
        profile?.company_id
          ? supabase
              .from("company_contracts")
              .select("*")
              .eq("company_id", profile.company_id)
              .eq("is_active", true)
              .order("created_at", { ascending: false })
              .limit(1)
              .maybeSingle()
          : Promise.resolve({ data: null }),
        // Weekly plan
        supabase
          .from("weekly_plans")
          .select("*, items:weekly_plan_items(*, dish:dishes(*))")
          .eq("user_id", userId)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle(),
      ])

      if (orderRes.data) setTodayOrder(orderRes.data)
      if (recentRes.data) setRecentOrders(recentRes.data)
      if (notifRes.data) setNotifications(notifRes.data)
      if (contractRes.data) setContract(contractRes.data)
      if (planRes.data) setWeeklyPlan(planRes.data)

      setLoading(false)
    }

    fetchData()
  }, [user?.user?.id, profile?.company_id, todayStr])

  const weekDays = useMemo(() => {
    const startOfWeek = new Date(today)
    const diff = (today.getDay() || 7) - 1
    startOfWeek.setDate(today.getDate() - diff)

    return Array.from({ length: 5 }, (_, i) => {
      const d = new Date(startOfWeek)
      d.setDate(startOfWeek.getDate() + i)
      return {
        dayOfWeek: i + 1,
        date: d.toISOString().split("T")[0],
        dayNum: d.getDate(),
        isToday: i + 1 === dayOfWeek,
        label: DAY_LABELS[i + 1],
      }
    })
  }, [dayOfWeek])

  if (loading) {
    return (
      <div className="space-y-6 p-4 md:p-6">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full rounded-xl" />
        <div className="grid grid-cols-5 gap-2">
          {Array.from({ length: 5 }, (_, i) => (
            <Skeleton key={i} className="h-16 rounded-xl" />
          ))}
        </div>
        <Skeleton className="h-48 w-full rounded-xl" />
      </div>
    )
  }

  return (
    <div className="space-y-6 p-4 md:p-6">
      {/* Greeting + Balance */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">
            {greeting}, {firstName}
          </h1>
          <p className="text-slate-500 text-sm mt-1">
            {today.toLocaleDateString("fr-FR", { weekday: "long", day: "numeric", month: "long", year: "numeric" })}
          </p>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          {contract?.payment_mode === "tickets" && profile && (
            <TicketBalance
              balance={profile.ticket_balance}
              total={contract.tickets_per_month || 24}
              compact
            />
          )}
          {profile?.company && (
            <Badge variant="outline" className="hidden md:flex">
              {profile.company.name}
            </Badge>
          )}
        </div>
      </div>

      {/* Today's order card */}
      <Card className={todayOrder
        ? "bg-gradient-to-r from-orange-50 to-amber-50 border-orange-200"
        : "bg-gradient-to-r from-slate-50 to-slate-100 border-slate-200"
      }>
        <CardContent className="pt-6">
          <div className="flex items-center gap-3 mb-4">
            <div className={`p-2 rounded-lg ${todayOrder ? "bg-orange-500" : "bg-slate-400"}`}>
              <Utensils className="h-5 w-5 text-white" />
            </div>
            <div className="flex-1">
              <h2 className="font-semibold text-slate-900">
                {todayOrder ? "Votre repas du jour" : "Pas de commande aujourd'hui"}
              </h2>
              {todayOrder?.dish && (
                <p className="text-sm text-slate-600">{todayOrder.dish.name}</p>
              )}
            </div>
            {todayOrder && (
              <OrderStatusBadge status={todayOrder.status} />
            )}
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
            {todayOrder?.status === "confirmed" && (
              <Button asChild className="flex-1 bg-orange-500 hover:bg-orange-600 text-white gap-2">
                <Link to="/app/employee/qrcode">
                  <QrCode className="h-4 w-4" />
                  Voir mon QR code
                </Link>
              </Button>
            )}
            <Button asChild variant={todayOrder ? "outline" : "default"}
              className={!todayOrder ? "flex-1 bg-orange-500 hover:bg-orange-600 text-white gap-2" : "gap-2"}>
              <Link to="/app/employee/menu">
                <ShoppingBag className="h-4 w-4" />
                {todayOrder ? "Menu" : "Planifier mes repas"}
              </Link>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Week calendar strip */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {weekDays.map((day) => {
          const planItem = weeklyPlan?.items?.find(
            (item) => item.day_of_week === day.dayOfWeek
          )
          const hasSelection = !!planItem && !planItem.is_cancelled
          return (
            <Link
              key={day.dayOfWeek}
              to="/app/employee/menu"
              className={`flex flex-col items-center min-w-[56px] px-2 py-2 rounded-xl transition-all ${
                day.isToday
                  ? "bg-orange-500 text-white shadow-lg"
                  : hasSelection
                  ? "bg-orange-50 border border-orange-200"
                  : "bg-slate-100 hover:bg-slate-200"
              }`}
            >
              <span className="text-[10px] font-medium uppercase">
                {day.label.slice(0, 3)}
              </span>
              <span className={`text-lg font-bold leading-tight ${
                day.isToday ? "text-white" : "text-slate-900"
              }`}>
                {day.dayNum}
              </span>
              {hasSelection && (
                <div className={`h-1.5 w-1.5 rounded-full mt-0.5 ${
                  day.isToday ? "bg-white" : "bg-orange-500"
                }`} />
              )}
            </Link>
          )
        })}
      </div>

      {/* Ticket balance (expanded) for ticket companies */}
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

      {/* Recent orders */}
      <Card>
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Commandes recentes</CardTitle>
            <Button asChild variant="ghost" size="sm" className="text-orange-500 gap-1">
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
              {recentOrders.map((order) => (
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

      {/* Notifications */}
      {notifications.length > 0 && (
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-base flex items-center gap-2">
              <Bell className="h-4 w-4 text-orange-500" />
              Notifications
              <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100 text-xs">
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

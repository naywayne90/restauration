import { useCallback, useEffect, useMemo, useState } from "react"
import { Clock, Utensils, Calendar, ChevronDown } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"
import type { Order, Dish, OrderStatus } from "@/lib/types"
import { CURRENCY } from "@/lib/constants"
import { OrderStatusBadge } from "@/components/shared/StatusBadge"
import { PriceDisplay } from "@/components/shared/PriceDisplay"

const MONTHS = [
  "Janvier", "Fevrier", "Mars", "Avril", "Mai", "Juin",
  "Juillet", "Aout", "Septembre", "Octobre", "Novembre", "Decembre",
]

const STATUS_FILTERS: { value: string; label: string }[] = [
  { value: "all", label: "Tous les statuts" },
  { value: "confirmed", label: "Confirmee" },
  { value: "served", label: "Servie" },
  { value: "cancelled", label: "Annulee" },
  { value: "no_show", label: "Absent" },
]

const PAGE_SIZE = 20

export function MyOrders() {
  const { user } = useAuth()
  const [orders, setOrders] = useState<(Order & { dish?: Dish })[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date()
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`
  })
  const [statusFilter, setStatusFilter] = useState("all")

  const [year, month] = selectedMonth.split("-").map(Number)

  const fetchOrders = useCallback(async (offset = 0, append = false) => {
    if (!user?.user?.id) return

    if (offset === 0) setLoading(true)
    else setLoadingMore(true)

    const startDate = `${year}-${String(month).padStart(2, "0")}-01`
    const endDate = new Date(year, month, 0).toISOString().split("T")[0]

    let query = supabase
      .from("orders")
      .select("*, dish:dishes(*)")
      .eq("user_id", user.user.id)
      .gte("order_date", startDate)
      .lte("order_date", endDate)
      .order("order_date", { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1)

    if (statusFilter !== "all") {
      query = query.eq("status", statusFilter)
    }

    const { data, error } = await query

    if (!error && data) {
      if (append) {
        setOrders(prev => [...prev, ...data])
      } else {
        setOrders(data)
      }
      setHasMore(data.length === PAGE_SIZE)
    }

    setLoading(false)
    setLoadingMore(false)
  }, [user?.user?.id, year, month, statusFilter])

  useEffect(() => {
    setOrders([])
    setHasMore(true)
    fetchOrders(0, false)
  }, [fetchOrders])

  const loadMore = () => {
    if (!loadingMore && hasMore) {
      fetchOrders(orders.length, true)
    }
  }

  // Monthly summary
  const summary = useMemo(() => {
    const total = orders.length
    const served = orders.filter(o => o.status === "served").length
    const cancelled = orders.filter(o => o.status === "cancelled").length
    const totalSpent = orders
      .filter(o => o.status === "served")
      .reduce((sum, o) => sum + o.employee_share, 0)
    const totalCompany = orders
      .filter(o => o.status === "served")
      .reduce((sum, o) => sum + o.company_share, 0)

    return { total, served, cancelled, totalSpent, totalCompany }
  }, [orders])

  // Month navigation
  const monthOptions = useMemo(() => {
    const opts: { value: string; label: string }[] = []
    const now = new Date()
    for (let i = 0; i < 6; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      const val = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`
      opts.push({ value: val, label: `${MONTHS[d.getMonth()]} ${d.getFullYear()}` })
    }
    return opts
  }, [])

  if (loading) {
    return (
      <div className="space-y-4 p-4 md:p-6">
        <Skeleton className="h-8 w-48" />
        <div className="grid grid-cols-3 gap-3">
          <Skeleton className="h-20 rounded-xl" />
          <Skeleton className="h-20 rounded-xl" />
          <Skeleton className="h-20 rounded-xl" />
        </div>
        {Array.from({ length: 5 }, (_, i) => (
          <Skeleton key={i} className="h-20 rounded-xl" />
        ))}
      </div>
    )
  }

  return (
    <div className="space-y-4 p-4 md:p-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mes commandes</h1>
        <p className="text-slate-500 text-sm mt-1">Historique de vos commandes MILY'S</p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <Select value={selectedMonth} onValueChange={setSelectedMonth}>
          <SelectTrigger className="w-48">
            <Calendar className="h-4 w-4 mr-2 text-slate-400" />
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {monthOptions.map(opt => (
              <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {STATUS_FILTERS.map(f => (
              <SelectItem key={f.value} value={f.value}>{f.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Monthly summary */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-slate-500">Total repas</p>
            <p className="text-2xl font-bold text-slate-900 mt-1">{summary.total}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-slate-500">Servis</p>
            <p className="text-2xl font-bold text-green-600 mt-1">{summary.served}</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-slate-500">Votre part</p>
            <p className="text-xl font-bold text-orange-600 mt-1">
              {summary.totalSpent.toLocaleString("fr-CI")} F
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-3">
            <p className="text-xs text-slate-500">Part entreprise</p>
            <p className="text-xl font-bold text-green-600 mt-1">
              {summary.totalCompany.toLocaleString("fr-CI")} F
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Orders list */}
      {orders.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Utensils className="h-12 w-12 text-slate-300 mb-3" />
          <p className="text-sm text-slate-500">Aucune commande pour cette periode.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {orders.map((order) => (
            <Card key={order.id} className="overflow-hidden">
              <CardContent className="p-0">
                <div className="flex items-center gap-3 p-4">
                  {order.dish?.photo_url ? (
                    <img
                      src={order.dish.photo_url}
                      alt={order.dish.name}
                      className="h-14 w-14 rounded-lg object-cover shrink-0"
                    />
                  ) : (
                    <div className="h-14 w-14 rounded-lg bg-slate-100 flex items-center justify-center shrink-0">
                      <Utensils className="h-6 w-6 text-slate-400" />
                    </div>
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-slate-900 text-sm truncate">
                      {order.dish?.name || "Plat"}
                    </p>
                    <p className="text-xs text-slate-400 flex items-center gap-1 mt-0.5">
                      <Clock className="h-3 w-3" />
                      {new Date(order.order_date).toLocaleDateString("fr-FR", {
                        weekday: "short", day: "numeric", month: "short"
                      })}
                    </p>
                    <OrderStatusBadge status={order.status} className="mt-1.5" />
                  </div>
                  <div className="text-right shrink-0 space-y-1">
                    <PriceDisplay amount={order.total_price} size="sm" />
                    {order.employee_share > 0 && (
                      <p className="text-xs text-orange-600 font-medium">
                        Vous: {order.employee_share.toLocaleString("fr-CI")} F
                      </p>
                    )}
                    {order.extras.length > 0 && (
                      <p className="text-[10px] text-slate-400">
                        +{order.extras.length} extra(s)
                      </p>
                    )}
                  </div>
                </div>
                {order.special_instructions && (
                  <div className="px-4 pb-3 pt-0">
                    <p className="text-xs text-slate-500 bg-slate-50 rounded px-2 py-1 italic">
                      {order.special_instructions}
                    </p>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}

          {hasMore && (
            <Button
              variant="outline"
              className="w-full gap-2"
              onClick={loadMore}
              disabled={loadingMore}
            >
              {loadingMore ? (
                <span className="animate-spin h-4 w-4 border-2 border-slate-400 border-t-transparent rounded-full" />
              ) : (
                <ChevronDown className="h-4 w-4" />
              )}
              Charger plus
            </Button>
          )}
        </div>
      )}
    </div>
  )
}

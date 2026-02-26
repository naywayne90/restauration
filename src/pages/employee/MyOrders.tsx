import { Clock, Utensils, Calendar, ChevronDown, XCircle } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  Dialog, DialogContent, DialogDescription, DialogFooter,
  DialogHeader, DialogTitle
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { useOrders } from "@/hooks/use-orders"
import { CURRENCY } from "@/lib/constants"
import { OrderStatusBadge } from "@/components/shared/StatusBadge"
import { PriceDisplay } from "@/components/shared/PriceDisplay"

const STATUS_FILTERS: { value: string; label: string }[] = [
  { value: "all", label: "Tous" },
  { value: "confirmed", label: "Confirmée" },
  { value: "served", label: "Servie" },
  { value: "cancelled", label: "Annulée" },
  { value: "no_show", label: "Absent" },
]

export function MyOrders() {
  const {
    orders, loading, loadingMore, hasMore, loadMore,
    selectedMonth, setSelectedMonth, statusFilter, setStatusFilter,
    summary, monthOptions,
    cancelDialog, setCancelDialog, cancelReason, setCancelReason, handleCancelOrder,
  } = useOrders()

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

      {/* Month selector */}
      <Select value={selectedMonth} onValueChange={setSelectedMonth}>
        <SelectTrigger className="w-52">
          <Calendar className="h-4 w-4 mr-2 text-slate-400" />
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          {monthOptions.map(opt => (
            <SelectItem key={opt.value} value={opt.value}>{opt.label}</SelectItem>
          ))}
        </SelectContent>
      </Select>

      {/* Badge quick filters */}
      <div className="flex gap-2 flex-wrap">
        {STATUS_FILTERS.map(f => (
          <button
            key={f.value}
            type="button"
            onClick={() => setStatusFilter(f.value)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition-all duration-200 ${
              statusFilter === f.value
                ? "bg-orange-500 text-white shadow-sm"
                : "bg-slate-100 text-slate-600 hover:bg-slate-200"
            }`}
          >
            {f.label}
            {f.value === "all" && summary.total > 0 && (
              <span className="ml-1 opacity-80">{summary.total}</span>
            )}
            {f.value === "served" && summary.served > 0 && (
              <span className="ml-1 opacity-80">{summary.served}</span>
            )}
            {f.value === "cancelled" && summary.cancelled > 0 && (
              <span className="ml-1 opacity-80">{summary.cancelled}</span>
            )}
          </button>
        ))}
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
          <p className="text-sm text-slate-500">Aucune commande pour cette période.</p>
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
                    <div className="flex items-center gap-2 mt-1.5">
                      <OrderStatusBadge status={order.status} />
                      {order.status === "confirmed" && !order.ticket_used && (
                        <button
                          type="button"
                          onClick={() => setCancelDialog(order.id)}
                          className="text-[10px] text-red-500 hover:text-red-700 font-medium flex items-center gap-0.5 transition-colors"
                        >
                          <XCircle className="h-3 w-3" />
                          Annuler
                        </button>
                      )}
                    </div>
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
              className="w-full gap-2 hover:scale-105 transition-all"
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

      {/* Cancel order dialog */}
      <Dialog open={!!cancelDialog} onOpenChange={() => { setCancelDialog(null); setCancelReason("") }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Annuler cette commande</DialogTitle>
            <DialogDescription>
              Veuillez indiquer la raison de l'annulation. Cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <Textarea
            placeholder="Raison de l'annulation (obligatoire)..."
            value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)}
            className="min-h-[80px]"
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => { setCancelDialog(null); setCancelReason("") }}>Retour</Button>
            <Button variant="destructive" disabled={!cancelReason.trim()} onClick={handleCancelOrder}
              className="hover:scale-105 transition-all">
              Confirmer l'annulation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

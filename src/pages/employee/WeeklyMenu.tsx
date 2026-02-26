import { useCallback, useEffect, useMemo, useState } from "react"
import {
  Lock, CheckCircle2, Minus, Plus, AlertTriangle, Utensils, Calendar
} from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Dialog, DialogContent, DialogDescription, DialogFooter,
  DialogHeader, DialogTitle
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { useToast } from "@/components/ui/use-toast"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"
import type { Menu, MenuItem, WeeklyPlan, CompanyContract, ExtraItem } from "@/lib/types"
import { DAY_LABELS, DAY_SHORT_LABELS } from "@/lib/types"
import { CURRENCY, BASE_MEAL_PRICE } from "@/lib/constants"
import { DishCard } from "@/components/shared/DishCard"
import { CountdownTimer } from "@/components/shared/CountdownTimer"
import { PlanStatusBadge } from "@/components/shared/StatusBadge"
import { PriceSplit } from "@/components/shared/PriceDisplay"

function isDayLocked(weekStart: string, dayOfWeek: number): boolean {
  const d = new Date(weekStart + "T00:00:00")
  d.setDate(d.getDate() + dayOfWeek - 1)
  d.setDate(d.getDate() - 3)
  d.setHours(23, 59, 59, 999)
  return new Date() > d
}

interface DaySelection {
  dishId: string | null
  extras: ExtraItem[]
}

export function WeeklyMenu() {
  const { user } = useAuth()
  const { toast } = useToast()
  const [menus, setMenus] = useState<Menu[]>([])
  const [weeklyPlans, setWeeklyPlans] = useState<Map<string, WeeklyPlan>>(new Map())
  const [contract, setContract] = useState<CompanyContract | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [activeWeekIdx, setActiveWeekIdx] = useState(0)
  const [activeDayOfWeek, setActiveDayOfWeek] = useState(1)
  const [selections, setSelections] = useState<Map<string, Map<number, DaySelection>>>(new Map())
  const [cancelDialog, setCancelDialog] = useState<{ menuId: string; dayOfWeek: number } | null>(null)
  const [cancelReason, setCancelReason] = useState("")

  const profile = user?.profile

  useEffect(() => {
    if (!user?.user?.id) return

    const fetchData = async () => {
      setLoading(true)
      const userId = user.user.id
      const today = new Date().toISOString().split("T")[0]

      const { data: menuData } = await supabase
        .from("menus")
        .select("*, items:menu_items(*, dish:dishes(*))")
        .eq("is_published", true)
        .gte("week_end", today)
        .order("week_start", { ascending: true })
        .limit(4)

      if (menuData) {
        setMenus(menuData)

        const menuIds = menuData.map((m: Menu) => m.id)
        if (menuIds.length > 0) {
          const { data: planData } = await supabase
            .from("weekly_plans")
            .select("*, items:weekly_plan_items(*, dish:dishes(*))")
            .eq("user_id", userId)
            .in("menu_id", menuIds)

          if (planData) {
            const planMap = new Map<string, WeeklyPlan>()
            const selMap = new Map<string, Map<number, DaySelection>>()

            for (const plan of planData) {
              planMap.set(plan.menu_id, plan)
              const dayMap = new Map<number, DaySelection>()
              for (const item of plan.items || []) {
                dayMap.set(item.day_of_week, {
                  dishId: item.is_cancelled ? null : item.dish_id,
                  extras: item.extras || [],
                })
              }
              selMap.set(plan.menu_id, dayMap)
            }

            setWeeklyPlans(planMap)
            setSelections(selMap)
          }
        }
      }

      if (profile?.company_id) {
        const { data: contractData } = await supabase
          .from("company_contracts")
          .select("*")
          .eq("company_id", profile.company_id)
          .eq("is_active", true)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle()

        if (contractData) setContract(contractData)
      }

      setLoading(false)
    }

    fetchData()
  }, [user?.user?.id, profile?.company_id])

  const activeMenu = menus[activeWeekIdx]
  const workingDays = contract?.working_days || 5

  const dayMenuItems = useMemo(() => {
    if (!activeMenu?.items) return { starter: null as MenuItem | null, mainDishes: [] as MenuItem[], extras: [] as MenuItem[] }
    const dayItems = activeMenu.items.filter((i: MenuItem) => i.day_of_week === activeDayOfWeek)
    return {
      starter: dayItems.find((i: MenuItem) => i.is_starter) || null,
      mainDishes: dayItems.filter((i: MenuItem) => !i.is_starter && !i.dish?.is_extra),
      extras: dayItems.filter((i: MenuItem) => i.dish?.is_extra),
    }
  }, [activeMenu, activeDayOfWeek])

  const currentSelection = useMemo(() => {
    if (!activeMenu) return null
    return selections.get(activeMenu.id)?.get(activeDayOfWeek) || null
  }, [activeMenu, activeDayOfWeek, selections])

  const dayLocked = activeMenu ? isDayLocked(activeMenu.week_start, activeDayOfWeek) : true
  const plan = activeMenu ? weeklyPlans.get(activeMenu.id) : undefined
  const planConfirmed = plan?.status === "confirmed" || plan?.status === "locked"

  const selectDish = useCallback((dishId: string) => {
    if (!activeMenu || dayLocked) return
    setSelections(prev => {
      const next = new Map(prev)
      const dayMap = new Map(next.get(activeMenu.id) || new Map())
      const current = dayMap.get(activeDayOfWeek) || { dishId: null, extras: [] }
      dayMap.set(activeDayOfWeek, { ...current, dishId })
      next.set(activeMenu.id, dayMap)
      return next
    })
  }, [activeMenu, activeDayOfWeek, dayLocked])

  const updateExtra = useCallback((dishId: string, unitPrice: number, delta: number) => {
    if (!activeMenu || dayLocked) return
    setSelections(prev => {
      const next = new Map(prev)
      const dayMap = new Map(next.get(activeMenu.id) || new Map())
      const current = dayMap.get(activeDayOfWeek) || { dishId: null, extras: [] }
      const extras = [...current.extras]
      const idx = extras.findIndex(e => e.dish_id === dishId)

      if (idx >= 0) {
        const newQty = extras[idx].quantity + delta
        if (newQty <= 0) extras.splice(idx, 1)
        else extras[idx] = { ...extras[idx], quantity: newQty }
      } else if (delta > 0) {
        extras.push({ dish_id: dishId, quantity: 1, unit_price: unitPrice })
      }

      dayMap.set(activeDayOfWeek, { ...current, extras })
      next.set(activeMenu.id, dayMap)
      return next
    })
  }, [activeMenu, activeDayOfWeek, dayLocked])

  const dayTotal = useMemo(() => {
    if (!currentSelection?.dishId) return 0
    const basePriceVal = contract?.base_meal_price || BASE_MEAL_PRICE
    const extrasTotal = currentSelection.extras.reduce((sum, e) => sum + e.unit_price * e.quantity, 0)
    return basePriceVal + extrasTotal
  }, [currentSelection, contract])

  const subsidyRate = contract?.subsidy_rate || 90
  const companyShareDay = currentSelection?.dishId ? Math.round((contract?.base_meal_price || BASE_MEAL_PRICE) * subsidyRate / 100) : 0
  const employeeShareDay = dayTotal - companyShareDay

  const weekProgress = useMemo(() => {
    if (!activeMenu) return { selected: 0, total: workingDays }
    const dayMap = selections.get(activeMenu.id) || new Map()
    let count = 0
    for (let d = 1; d <= workingDays; d++) {
      if (dayMap.get(d)?.dishId) count++
    }
    return { selected: count, total: workingDays }
  }, [activeMenu, selections, workingDays])

  const handleValidate = async () => {
    if (!activeMenu || !user?.user?.id) return
    setSaving(true)

    try {
      const userId = user.user.id
      const dayMap = selections.get(activeMenu.id)

      let planId: string = weeklyPlans.get(activeMenu.id)?.id || ""
      if (!planId) {
        const { data: newPlan, error: planErr } = await supabase
          .from("weekly_plans")
          .insert({
            user_id: userId,
            menu_id: activeMenu.id,
            status: "confirmed",
            confirmed_at: new Date().toISOString(),
          })
          .select("id")
          .single()

        if (planErr) throw planErr
        planId = newPlan.id
      } else {
        await supabase
          .from("weekly_plans")
          .update({ status: "confirmed", confirmed_at: new Date().toISOString() })
          .eq("id", planId)
      }

      if (dayMap) {
        await supabase
          .from("weekly_plan_items")
          .delete()
          .eq("weekly_plan_id", planId)

        const items: Array<{
          weekly_plan_id: string
          day_of_week: number
          dish_id: string
          extras: ExtraItem[]
          is_locked: boolean
        }> = []

        for (const [day, sel] of dayMap.entries()) {
          if (sel.dishId) {
            items.push({
              weekly_plan_id: planId,
              day_of_week: day,
              dish_id: sel.dishId,
              extras: sel.extras,
              is_locked: isDayLocked(activeMenu.week_start, day),
            })
          }
        }

        if (items.length > 0) {
          const { error: itemErr } = await supabase.from("weekly_plan_items").insert(items)
          if (itemErr) throw itemErr
        }
      }

      if (dayMap) {
        for (const [day, sel] of dayMap.entries()) {
          if (!sel.dishId) continue
          const orderDate = new Date(activeMenu.week_start + "T00:00:00")
          orderDate.setDate(orderDate.getDate() + day - 1)
          const basePriceVal = contract?.base_meal_price || BASE_MEAL_PRICE
          const extrasTotal = sel.extras.reduce((s, e) => s + e.unit_price * e.quantity, 0)

          await supabase
            .from("orders")
            .upsert({
              user_id: userId,
              dish_id: sel.dishId,
              site_id: profile?.site_id || null,
              order_date: orderDate.toISOString().split("T")[0],
              extras: sel.extras,
              status: "confirmed",
              total_price: basePriceVal + extrasTotal,
            }, { onConflict: "user_id,order_date" })
        }
      }

      toast({ title: "Planning valide !", description: `${weekProgress.selected} repas confirmes pour la semaine.` })

      const { data: refreshedPlan } = await supabase
        .from("weekly_plans")
        .select("*, items:weekly_plan_items(*, dish:dishes(*))")
        .eq("id", planId)
        .single()

      if (refreshedPlan) {
        setWeeklyPlans(prev => {
          const next = new Map(prev)
          next.set(activeMenu.id, refreshedPlan)
          return next
        })
      }
    } catch (err) {
      console.error(err)
      toast({ title: "Erreur", description: "Impossible de valider le planning.", variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  const handleCancelDay = async () => {
    if (!cancelDialog || !cancelReason.trim()) return
    const { menuId, dayOfWeek } = cancelDialog
    const planData = weeklyPlans.get(menuId)
    if (!planData) return

    const item = planData.items?.find(i => i.day_of_week === dayOfWeek)
    if (!item) return

    try {
      await supabase
        .from("weekly_plan_items")
        .update({ is_cancelled: true, cancel_reason: cancelReason })
        .eq("id", item.id)

      const menu = menus.find(m => m.id === menuId)
      if (menu) {
        const orderDate = new Date(menu.week_start + "T00:00:00")
        orderDate.setDate(orderDate.getDate() + dayOfWeek - 1)
        await supabase
          .from("orders")
          .update({ status: "cancelled", special_instructions: cancelReason })
          .eq("user_id", user!.user.id)
          .eq("order_date", orderDate.toISOString().split("T")[0])
      }

      setSelections(prev => {
        const next = new Map(prev)
        const dayMap = new Map(next.get(menuId) || new Map())
        dayMap.set(dayOfWeek, { dishId: null, extras: [] })
        next.set(menuId, dayMap)
        return next
      })

      toast({ title: "Repas annule", description: `${DAY_LABELS[dayOfWeek]} annule.` })
    } catch {
      toast({ title: "Erreur", description: "Impossible d'annuler.", variant: "destructive" })
    } finally {
      setCancelDialog(null)
      setCancelReason("")
    }
  }

  if (loading) {
    return (
      <div className="space-y-4 p-4 md:p-6">
        <Skeleton className="h-10 w-full rounded-lg" />
        <Skeleton className="h-12 w-full rounded-lg" />
        <Skeleton className="h-32 w-full rounded-xl" />
        <div className="grid grid-cols-2 gap-4">
          <Skeleton className="h-48 rounded-xl" />
          <Skeleton className="h-48 rounded-xl" />
        </div>
      </div>
    )
  }

  if (menus.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-20 px-4 text-center">
        <Calendar className="h-16 w-16 text-slate-300 mb-4" />
        <h2 className="text-lg font-semibold text-slate-900 mb-2">Aucun menu disponible</h2>
        <p className="text-sm text-slate-500 max-w-sm">
          Les menus des prochaines semaines n'ont pas encore ete publies.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-4 p-4 md:p-6 pb-32">
      {/* Week tabs */}
      <Tabs value={String(activeWeekIdx)} onValueChange={(v) => { setActiveWeekIdx(Number(v)); setActiveDayOfWeek(1) }}>
        <TabsList className="w-full">
          {menus.map((menu, idx) => {
            const start = new Date(menu.week_start + "T00:00:00")
            const end = new Date(menu.week_end + "T00:00:00")
            return (
              <TabsTrigger key={menu.id} value={String(idx)} className="flex-1 text-xs">
                {start.getDate()}-{end.getDate()} {start.toLocaleDateString("fr-FR", { month: "short" })}
              </TabsTrigger>
            )
          })}
        </TabsList>
      </Tabs>

      {plan && (
        <div className="flex items-center justify-between">
          <PlanStatusBadge status={plan.status} />
          {activeMenu?.selection_deadline && (
            <CountdownTimer deadline={activeMenu.selection_deadline} compact />
          )}
        </div>
      )}

      {activeMenu && (
        <div className="flex gap-1.5 overflow-x-auto pb-1">
          {Array.from({ length: workingDays }, (_, i) => i + 1).map((dow) => {
            const isActive = dow === activeDayOfWeek
            const locked = isDayLocked(activeMenu.week_start, dow)
            const dateObj = new Date(activeMenu.week_start + "T00:00:00")
            dateObj.setDate(dateObj.getDate() + dow - 1)
            const dayNum = dateObj.getDate()
            const sel = selections.get(activeMenu.id)?.get(dow)
            const hasSelection = !!sel?.dishId

            return (
              <button
                key={dow}
                type="button"
                onClick={() => setActiveDayOfWeek(dow)}
                className={`flex flex-col items-center min-w-[52px] px-2 py-2 rounded-xl transition-all duration-200 ${
                  isActive
                    ? "bg-orange-500 text-white shadow-lg scale-105"
                    : locked
                    ? "bg-slate-100 text-slate-400"
                    : hasSelection
                    ? "bg-orange-50 text-orange-700 border border-orange-200"
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
              >
                <span className="text-[10px] font-medium uppercase">{DAY_SHORT_LABELS[dow]}</span>
                <span className={`text-lg font-bold leading-tight ${isActive ? "text-white" : "text-slate-900"}`}>{dayNum}</span>
                {locked ? (
                  <Lock className={`h-3 w-3 mt-0.5 ${isActive ? "text-orange-200" : "text-slate-400"}`} />
                ) : hasSelection ? (
                  <CheckCircle2 className={`h-3 w-3 mt-0.5 ${isActive ? "text-white" : "text-orange-500"}`} />
                ) : (
                  <div className="h-3 mt-0.5" />
                )}
              </button>
            )
          })}
        </div>
      )}

      {activeMenu && (
        <div className="space-y-4">
          {dayLocked && (
            <div className="flex items-center gap-2 p-3 bg-slate-100 rounded-lg border border-slate-200">
              <Lock className="h-4 w-4 text-slate-500 shrink-0" />
              <p className="text-xs text-slate-600">Ce jour est verrouille (J-3 depasse). Modifications impossibles.</p>
            </div>
          )}

          {dayMenuItems.starter?.dish && (
            <Card className="border-emerald-200 bg-emerald-50/50">
              <CardHeader className="pb-2">
                <div className="flex items-center gap-2">
                  <Badge className="bg-emerald-100 text-emerald-700 hover:bg-emerald-100 text-[10px]">
                    ENTREE FIXE
                  </Badge>
                  <span className="text-xs text-slate-400">Incluse dans le menu</span>
                </div>
              </CardHeader>
              <CardContent>
                <DishCard dish={dayMenuItems.starter.dish} compact selected />
              </CardContent>
            </Card>
          )}

          {dayMenuItems.mainDishes.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                <Utensils className="h-4 w-4 text-orange-500" />
                Plat principal — Choisissez 1
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {dayMenuItems.mainDishes.map((item) => {
                  if (!item.dish) return null
                  return (
                    <DishCard
                      key={item.id}
                      dish={item.dish}
                      selected={currentSelection?.dishId === item.dish_id}
                      locked={dayLocked}
                      onSelect={() => selectDish(item.dish_id)}
                    />
                  )
                })}
              </div>
            </div>
          )}

          {dayMenuItems.extras.length > 0 && (
            <div>
              <h3 className="text-sm font-semibold text-slate-700 mb-3 flex items-center gap-2">
                <Plus className="h-4 w-4 text-orange-500" />
                Extras — 100% a votre charge
              </h3>
              <div className="space-y-2">
                {dayMenuItems.extras.map((item) => {
                  if (!item.dish) return null
                  const extraQty = currentSelection?.extras.find(e => e.dish_id === item.dish_id)?.quantity || 0

                  return (
                    <div key={item.id} className="flex items-center gap-3 p-3 bg-white rounded-lg border border-slate-200">
                      {item.dish.photo_url && (
                        <img src={item.dish.photo_url} alt={item.dish.name} className="h-10 w-10 rounded-lg object-cover shrink-0" />
                      )}
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-slate-900 truncate">{item.dish.name}</p>
                        <p className="text-xs text-orange-600 font-semibold">+{item.dish.price.toLocaleString("fr-CI")} {CURRENCY}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        <Button variant="outline" size="icon" className="h-7 w-7" disabled={dayLocked || extraQty === 0}
                          onClick={() => updateExtra(item.dish_id, item.dish!.price, -1)}>
                          <Minus className="h-3 w-3" />
                        </Button>
                        <span className="w-6 text-center text-sm font-semibold">{extraQty}</span>
                        <Button variant="outline" size="icon" className="h-7 w-7" disabled={dayLocked}
                          onClick={() => updateExtra(item.dish_id, item.dish!.price, 1)}>
                          <Plus className="h-3 w-3" />
                        </Button>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          )}

          {currentSelection?.dishId && (
            <Card className="border-orange-200">
              <CardContent className="pt-4">
                <PriceSplit total={dayTotal} companyShare={companyShareDay} employeeShare={employeeShareDay} />
              </CardContent>
            </Card>
          )}

          {planConfirmed && currentSelection?.dishId && !dayLocked && (
            <Button variant="outline" className="w-full text-red-600 border-red-200 hover:bg-red-50 gap-2"
              onClick={() => setCancelDialog({ menuId: activeMenu.id, dayOfWeek: activeDayOfWeek })}>
              <AlertTriangle className="h-4 w-4" />
              Annuler ce repas
            </Button>
          )}
        </div>
      )}

      {/* Sticky bottom bar */}
      <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-slate-200 p-4 shadow-lg z-40 md:left-64">
        <div className="flex items-center gap-4 max-w-3xl mx-auto">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs text-slate-500">Progression</span>
              <span className="text-xs font-semibold text-orange-600">{weekProgress.selected}/{weekProgress.total} jours</span>
            </div>
            <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
              <div className="h-full bg-orange-500 rounded-full transition-all duration-300"
                style={{ width: `${(weekProgress.selected / weekProgress.total) * 100}%` }} />
            </div>
          </div>
          <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2 px-6"
            disabled={saving || weekProgress.selected === 0} onClick={handleValidate}>
            {saving ? (
              <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
            ) : (
              <CheckCircle2 className="h-4 w-4" />
            )}
            Valider la semaine
          </Button>
        </div>
      </div>

      {/* Cancel dialog */}
      <Dialog open={!!cancelDialog} onOpenChange={() => { setCancelDialog(null); setCancelReason("") }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Annuler ce repas</DialogTitle>
            <DialogDescription>
              Veuillez indiquer la raison de l'annulation. Cette action est irreversible.
            </DialogDescription>
          </DialogHeader>
          <Textarea placeholder="Raison de l'annulation (obligatoire)..." value={cancelReason}
            onChange={(e) => setCancelReason(e.target.value)} className="min-h-[80px]" />
          <DialogFooter>
            <Button variant="outline" onClick={() => { setCancelDialog(null); setCancelReason("") }}>Retour</Button>
            <Button variant="destructive" disabled={!cancelReason.trim()} onClick={handleCancelDay}>
              Confirmer l'annulation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

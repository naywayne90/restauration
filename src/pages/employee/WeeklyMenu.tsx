import { useEffect } from "react"
import {
  Lock, CheckCircle2, Minus, Plus, AlertTriangle, Utensils, Calendar,
  ChevronDown, ChevronUp
} from "lucide-react"
import { Card, CardContent, CardHeader } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Skeleton } from "@/components/ui/skeleton"
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Separator } from "@/components/ui/separator"
import {
  Dialog, DialogContent, DialogDescription, DialogFooter,
  DialogHeader, DialogTitle
} from "@/components/ui/dialog"
import { Textarea } from "@/components/ui/textarea"
import { useWeeklyMenu } from "@/hooks/use-weekly-menu"
import { DAY_SHORT_LABELS } from "@/lib/types"
import { CURRENCY } from "@/lib/constants"
import { DishCard } from "@/components/shared/DishCard"
import { CountdownTimer } from "@/components/shared/CountdownTimer"
import { PlanStatusBadge } from "@/components/shared/StatusBadge"
import { PriceSplit } from "@/components/shared/PriceDisplay"

export function WeeklyMenu() {
  const {
    menus, activeMenu, loading, saving, activeWeekIdx, setActiveWeekIdx,
    activeDayOfWeek, setActiveDayOfWeek, workingDays, dayMenuItems,
    currentSelection, dayLocked, plan, planConfirmed, contract,
    selectDish, updateExtra, dayTotal, companyShareDay, employeeShareDay,
    weekProgress, weekSummary, totalEmployeeShare, totalExtras, totalCompanyShare,
    showConfirmation, setShowConfirmation, confirmationSuccess, setConfirmationSuccess,
    handleValidate, isDayLocked, extrasOpen, setExtrasOpen, selections, basePriceVal,
    cancelDayDialog, setCancelDayDialog, cancelDayReason, setCancelDayReason, handleCancelDay,
  } = useWeeklyMenu()

  // Auto-close confirmation dialog after success
  useEffect(() => {
    if (confirmationSuccess) {
      const timer = setTimeout(() => {
        setShowConfirmation(false)
        setConfirmationSuccess(false)
      }, 2500)
      return () => clearTimeout(timer)
    }
  }, [confirmationSuccess, setShowConfirmation, setConfirmationSuccess])

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
          Les menus des prochaines semaines n'ont pas encore été publiés.
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

      {/* Day tabs with check badges */}
      {activeMenu && (
        <div className="flex gap-1.5 overflow-x-auto pb-1">
          {Array.from({ length: workingDays }, (_, i) => i + 1).map((dow) => {
            const isActive = dow === activeDayOfWeek
            const locked = isDayLocked(dow)
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
                    ? "bg-red-50 text-red-400 border border-red-200"
                    : hasSelection
                    ? "bg-green-50 text-green-700 border border-green-300"
                    : "bg-slate-100 text-slate-600 hover:bg-slate-200"
                }`}
              >
                <span className="text-[10px] font-medium uppercase">{DAY_SHORT_LABELS[dow]}</span>
                <span className={`text-lg font-bold leading-tight ${isActive ? "text-white" : locked ? "text-red-400" : hasSelection ? "text-green-800" : "text-slate-900"}`}>{dayNum}</span>
                {locked ? (
                  <Lock className={`h-3 w-3 mt-0.5 ${isActive ? "text-orange-200" : "text-red-400"}`} />
                ) : hasSelection ? (
                  <CheckCircle2 className={`h-3 w-3 mt-0.5 ${isActive ? "text-white" : "text-green-500"}`} />
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
            <div className="flex items-center gap-2 p-3 bg-red-50 rounded-lg border border-red-200">
              <Lock className="h-4 w-4 text-red-500 shrink-0" />
              <p className="text-xs text-red-600">Ce jour est verrouillé (J-2 dépassé). Modifications impossibles.</p>
            </div>
          )}

          {/* Starter */}
          {dayMenuItems.starter?.dish && (
            <Card className="border-emerald-200 bg-emerald-50/50">
              <CardHeader className="pb-2">
                <div className="flex items-center gap-2">
                  <Badge className="bg-emerald-100 text-emerald-700 hover:bg-emerald-100 text-[10px]">
                    ENTRÉE FIXE
                  </Badge>
                  <span className="text-xs text-slate-400">Incluse dans le menu</span>
                </div>
              </CardHeader>
              <CardContent>
                <DishCard dish={dayMenuItems.starter.dish} compact selected />
              </CardContent>
            </Card>
          )}

          {/* Main dishes */}
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

          {/* Collapsible extras */}
          {dayMenuItems.extras.length > 0 && (
            <div>
              <button
                type="button"
                onClick={() => setExtrasOpen(!extrasOpen)}
                className="w-full flex items-center justify-between text-sm font-semibold text-slate-700 mb-3 hover:text-orange-600 transition-colors"
              >
                <span className="flex items-center gap-2">
                  <Plus className="h-4 w-4 text-orange-500" />
                  Extras — 100% à votre charge
                  {currentSelection?.extras && currentSelection.extras.length > 0 && (
                    <Badge className="bg-orange-100 text-orange-700 hover:bg-orange-100 text-[10px]">
                      {currentSelection.extras.reduce((s, e) => s + e.quantity, 0)}
                    </Badge>
                  )}
                </span>
                {extrasOpen ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
              </button>
              {extrasOpen && (
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
              )}
            </div>
          )}

          {/* Day price split */}
          {currentSelection?.dishId && (
            <Card className="border-orange-200">
              <CardContent className="pt-4">
                <PriceSplit total={dayTotal} companyShare={companyShareDay} employeeShare={employeeShareDay} />
              </CardContent>
            </Card>
          )}

          {/* Cancel day button */}
          {planConfirmed && currentSelection?.dishId && !dayLocked && (
            <Button variant="outline" className="w-full text-red-600 border-red-200 hover:bg-red-50 gap-2 hover:scale-105 transition-all"
              onClick={() => setCancelDayDialog({ menuId: activeMenu.id, dayOfWeek: activeDayOfWeek })}>
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
          <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2 px-6 hover:scale-105 transition-all"
            disabled={saving || weekProgress.selected === 0} onClick={() => setShowConfirmation(true)}>
            <CheckCircle2 className="h-4 w-4" />
            Valider la semaine
          </Button>
        </div>
      </div>

      {/* Confirmation dialog (Screen 3) */}
      <Dialog open={showConfirmation} onOpenChange={setShowConfirmation}>
        <DialogContent className="max-w-md max-h-[80vh] overflow-y-auto">
          {confirmationSuccess ? (
            <div className="flex flex-col items-center py-8">
              <div className="h-16 w-16 rounded-full bg-green-100 flex items-center justify-center animate-bounce">
                <CheckCircle2 className="h-10 w-10 text-green-500" />
              </div>
              <p className="mt-4 text-lg font-semibold text-green-700">Planning validé !</p>
              <p className="text-sm text-slate-500 mt-1">Vos {weekProgress.selected} repas sont confirmés.</p>
            </div>
          ) : (
            <>
              <DialogHeader>
                <DialogTitle>Récapitulatif de la semaine</DialogTitle>
                <DialogDescription>
                  Vérifiez votre sélection avant de confirmer.
                </DialogDescription>
              </DialogHeader>

              <div className="space-y-3 my-4">
                {weekSummary.map((item) => (
                  <div key={item.day} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{item.dayLabel}</p>
                      {item.starterName && (
                        <p className="text-xs text-emerald-600">{item.starterName}</p>
                      )}
                      <p className="text-xs text-slate-600">{item.dishName}</p>
                      {item.extrasTotal > 0 && (
                        <p className="text-[10px] text-orange-600">+{item.extrasTotal.toLocaleString("fr-CI")} {CURRENCY} extras</p>
                      )}
                    </div>
                    <p className="text-sm font-semibold text-slate-700">
                      {basePriceVal.toLocaleString("fr-CI")} F
                    </p>
                  </div>
                ))}
              </div>

              <Separator />

              <div className="space-y-2 pt-2">
                <div className="flex justify-between text-sm">
                  <span className="text-slate-500">{weekSummary.length} repas × {basePriceVal.toLocaleString("fr-CI")} F</span>
                  <span className="font-medium">{(weekSummary.length * basePriceVal).toLocaleString("fr-CI")} {CURRENCY}</span>
                </div>
                {totalExtras > 0 && (
                  <div className="flex justify-between text-sm">
                    <span className="text-orange-600">Extras</span>
                    <span className="text-orange-600 font-medium">+{totalExtras.toLocaleString("fr-CI")} {CURRENCY}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm">
                  <span className="text-green-600">Part entreprise</span>
                  <span className="text-green-600 font-medium">-{totalCompanyShare.toLocaleString("fr-CI")} {CURRENCY}</span>
                </div>
                <Separator />
                <div className="flex justify-between text-base font-bold">
                  <span className="text-orange-600">Votre part</span>
                  <span className="text-orange-600">{(totalEmployeeShare + totalExtras).toLocaleString("fr-CI")} {CURRENCY}</span>
                </div>
              </div>

              <DialogFooter className="mt-4">
                <Button variant="outline" onClick={() => setShowConfirmation(false)}>Retour</Button>
                <Button className="bg-orange-500 hover:bg-orange-600 text-white gap-2 hover:scale-105 transition-all"
                  disabled={saving} onClick={handleValidate}>
                  {saving ? (
                    <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
                  ) : (
                    <CheckCircle2 className="h-4 w-4" />
                  )}
                  Confirmer
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>

      {/* Cancel day dialog */}
      <Dialog open={!!cancelDayDialog} onOpenChange={() => { setCancelDayDialog(null); setCancelDayReason("") }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Annuler ce repas</DialogTitle>
            <DialogDescription>
              Veuillez indiquer la raison de l'annulation. Cette action est irréversible.
            </DialogDescription>
          </DialogHeader>
          <Textarea placeholder="Raison de l'annulation (obligatoire)..." value={cancelDayReason}
            onChange={(e) => setCancelDayReason(e.target.value)} className="min-h-[80px]" />
          <DialogFooter>
            <Button variant="outline" onClick={() => { setCancelDayDialog(null); setCancelDayReason("") }}>Retour</Button>
            <Button variant="destructive" disabled={!cancelDayReason.trim()} onClick={handleCancelDay}
              className="hover:scale-105 transition-all">
              Confirmer l'annulation
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

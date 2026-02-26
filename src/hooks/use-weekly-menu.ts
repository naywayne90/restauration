import { useCallback, useEffect, useMemo, useState } from "react"
import { useAuth } from "./use-auth"
import { supabase } from "@/lib/supabase"
import { useToast } from "@/components/ui/use-toast"
import type { Menu, MenuItem, WeeklyPlan, CompanyContract, ExtraItem, Dish } from "@/lib/types"
import { BASE_MEAL_PRICE } from "@/lib/constants"
import { DAY_LABELS } from "@/lib/types"

// ── Mock data ──
const MOCK_STARTERS: Dish[] = [
  { id: "ms1", name: "Salade composée", description: "Salade verte, tomates, concombres, oeufs", category: "entree", price: 0, is_available: true, is_starter: true, is_extra: false, is_vegetarian: true, is_vegan: false, is_featured: false, sort_order: 1, photo_url: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400", created_at: "", updated_at: "" },
  { id: "ms2", name: "Soupe de poisson", description: "Soupe de poisson frais aux épices", category: "entree", price: 0, is_available: true, is_starter: true, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 1, photo_url: "https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400", created_at: "", updated_at: "" },
]

const MOCK_MAIN_DISHES: Dish[] = [
  { id: "md1", name: "Garba", description: "Attiéké au thon frit, piment et oignon", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 2, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Garba_dish.jpg/640px-Garba_dish.jpg", created_at: "", updated_at: "" },
  { id: "md2", name: "Poulet braisé", description: "Poulet braisé aux épices, alloco et attiéké", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 3, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Braised_chicken.jpg/640px-Braised_chicken.jpg", created_at: "", updated_at: "" },
  { id: "md3", name: "Foutou banane sauce graine", description: "Foutou de banane plantain avec sauce graine de palme", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 4, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Foutou_banane.jpg/640px-Foutou_banane.jpg", created_at: "", updated_at: "" },
  { id: "md4", name: "Riz sauce arachide", description: "Riz blanc avec sauce arachide et viande", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 5, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/ce/Maafe.jpg/640px-Maafe.jpg", created_at: "", updated_at: "" },
]

const MOCK_EXTRAS: Dish[] = [
  { id: "me1", name: "Fruits de saison", description: "Assortiment de fruits frais", category: "dessert", price: 500, is_available: true, is_starter: false, is_extra: true, is_vegetarian: true, is_vegan: true, is_featured: false, sort_order: 10, photo_url: "https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=400", created_at: "", updated_at: "" },
  { id: "me2", name: "Yaourt", description: "Yaourt nature ou sucré", category: "dessert", price: 500, is_available: true, is_starter: false, is_extra: true, is_vegetarian: true, is_vegan: false, is_featured: false, sort_order: 11, photo_url: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400", created_at: "", updated_at: "" },
  { id: "me3", name: "Bissap", description: "Jus d'hibiscus frais", category: "boisson", price: 300, is_available: true, is_starter: false, is_extra: true, is_vegetarian: true, is_vegan: true, is_featured: false, sort_order: 12, photo_url: "https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400", created_at: "", updated_at: "" },
  { id: "me4", name: "Gnamakoudji", description: "Jus de gingembre pimenté", category: "boisson", price: 300, is_available: true, is_starter: false, is_extra: true, is_vegetarian: true, is_vegan: true, is_featured: false, sort_order: 13, photo_url: "https://images.unsplash.com/photo-1534353473418-4cfa6c56fd38?w=400", created_at: "", updated_at: "" },
  { id: "me5", name: "Eau minérale", description: "Bouteille 50cl", category: "boisson", price: 200, is_available: true, is_starter: false, is_extra: true, is_vegetarian: true, is_vegan: true, is_featured: false, sort_order: 14, photo_url: "https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400", created_at: "", updated_at: "" },
]

function buildMockMenuItems(day: number): { starter: MenuItem | null; mainDishes: MenuItem[]; extras: MenuItem[] } {
  const starterDish = MOCK_STARTERS[day % MOCK_STARTERS.length]
  const start = day % MOCK_MAIN_DISHES.length
  const dishes = [
    MOCK_MAIN_DISHES[start],
    MOCK_MAIN_DISHES[(start + 1) % MOCK_MAIN_DISHES.length],
    MOCK_MAIN_DISHES[(start + 2) % MOCK_MAIN_DISHES.length],
  ]
  return {
    starter: { id: `si-${day}`, menu_id: "", dish_id: starterDish.id, day_of_week: day, is_starter: true, sort_order: 1, created_at: "", dish: starterDish },
    mainDishes: dishes.map((d, i) => ({ id: `mi-${day}-${i}`, menu_id: "", dish_id: d.id, day_of_week: day, is_starter: false, sort_order: i + 2, created_at: "", dish: d })),
    extras: MOCK_EXTRAS.map((d, i) => ({ id: `ei-${day}-${i}`, menu_id: "", dish_id: d.id, day_of_week: day, is_starter: false, sort_order: i + 10, created_at: "", dish: d })),
  }
}

export interface DaySelection {
  dishId: string | null
  extras: ExtraItem[]
}

function isDayLocked(weekStart: string, dayOfWeek: number): boolean {
  const d = new Date(weekStart + "T00:00:00")
  d.setDate(d.getDate() + dayOfWeek - 1)
  d.setDate(d.getDate() - 2) // J-2
  d.setHours(23, 59, 59, 999)
  return new Date() > d
}

export function useWeeklyMenu() {
  const { user } = useAuth()
  const { toast } = useToast()
  const profile = user?.profile

  const [menus, setMenus] = useState<Menu[]>([])
  const [weeklyPlans, setWeeklyPlans] = useState<Map<string, WeeklyPlan>>(new Map())
  const [contract, setContract] = useState<CompanyContract | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [showConfirmation, setShowConfirmation] = useState(false)
  const [confirmationSuccess, setConfirmationSuccess] = useState(false)
  const [activeWeekIdx, setActiveWeekIdx] = useState(0)
  const [activeDayOfWeek, setActiveDayOfWeek] = useState(() => {
    const d = new Date().getDay()
    return d >= 1 && d <= 5 ? d : 1
  })
  const [selections, setSelections] = useState<Map<string, Map<number, DaySelection>>>(new Map())
  const [extrasOpen, setExtrasOpen] = useState(false)
  const [cancelDayDialog, setCancelDayDialog] = useState<{ menuId: string; dayOfWeek: number } | null>(null)
  const [cancelDayReason, setCancelDayReason] = useState("")

  const useMock = !user?.user?.id

  useEffect(() => {
    if (useMock) {
      // Build mock menus
      const now = new Date()
      const monday = new Date(now)
      monday.setDate(now.getDate() - ((now.getDay() || 7) - 1))
      const fri = new Date(monday)
      fri.setDate(monday.getDate() + 4)

      const mockMenu: Menu = {
        id: "mock-menu-1",
        name: `Menu semaine du ${monday.getDate()} ${monday.toLocaleDateString("fr-FR", { month: "long" })}`,
        week_start: monday.toISOString().split("T")[0],
        week_end: fri.toISOString().split("T")[0],
        is_published: true,
        created_at: "", updated_at: "",
      }
      setMenus([mockMenu])
      setLoading(false)
      return
    }

    const fetchData = async () => {
      setLoading(true)
      const userId = user!.user.id
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
          .from("company_contracts").select("*")
          .eq("company_id", profile.company_id).eq("is_active", true)
          .order("created_at", { ascending: false }).limit(1).maybeSingle()
        if (contractData) setContract(contractData)
      }

      setLoading(false)
    }
    fetchData()
  }, [user?.user?.id, profile?.company_id, useMock])

  const activeMenu = menus[activeWeekIdx]
  const workingDays = contract?.working_days || 5

  const dayMenuItems = useMemo(() => {
    if (useMock && activeMenu) return buildMockMenuItems(activeDayOfWeek)
    if (!activeMenu?.items) return { starter: null as MenuItem | null, mainDishes: [] as MenuItem[], extras: [] as MenuItem[] }
    const dayItems = activeMenu.items.filter((i: MenuItem) => i.day_of_week === activeDayOfWeek)
    return {
      starter: dayItems.find((i: MenuItem) => i.is_starter) || null,
      mainDishes: dayItems.filter((i: MenuItem) => !i.is_starter && !i.dish?.is_extra),
      extras: dayItems.filter((i: MenuItem) => i.dish?.is_extra),
    }
  }, [activeMenu, activeDayOfWeek, useMock])

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

  // Compute totals
  const subsidyRate = contract?.subsidy_rate || 90
  const basePriceVal = contract?.base_meal_price || BASE_MEAL_PRICE

  const dayTotal = useMemo(() => {
    if (!currentSelection?.dishId) return 0
    const extrasTotal = currentSelection.extras.reduce((sum, e) => sum + e.unit_price * e.quantity, 0)
    return basePriceVal + extrasTotal
  }, [currentSelection, basePriceVal])

  const companyShareDay = currentSelection?.dishId ? Math.round(basePriceVal * subsidyRate / 100) : 0
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

  // Week summary for confirmation
  const weekSummary = useMemo(() => {
    if (!activeMenu) return []
    const dayMap = selections.get(activeMenu.id) || new Map()
    const items: Array<{ day: number; dayLabel: string; dishName: string; extrasTotal: number; starterName?: string }> = []

    for (let d = 1; d <= workingDays; d++) {
      const sel = dayMap.get(d)
      if (!sel?.dishId) continue

      // Find dish name
      let dishName = "Plat sélectionné"
      if (useMock) {
        const mi = buildMockMenuItems(d)
        dishName = mi.mainDishes.find(m => m.dish?.id === sel.dishId)?.dish?.name || dishName
      } else if (activeMenu.items) {
        dishName = activeMenu.items.find((i: MenuItem) => i.dish_id === sel.dishId && i.day_of_week === d)?.dish?.name || dishName
      }

      // Find starter
      let starterName: string | undefined
      if (useMock) {
        starterName = buildMockMenuItems(d).starter?.dish?.name
      } else if (activeMenu.items) {
        starterName = activeMenu.items.find((i: MenuItem) => i.is_starter && i.day_of_week === d)?.dish?.name
      }

      const extrasTotal = sel.extras.reduce((s: number, e: ExtraItem) => s + e.unit_price * e.quantity, 0)
      items.push({ day: d, dayLabel: DAY_LABELS[d], dishName, extrasTotal, starterName })
    }
    return items
  }, [activeMenu, selections, workingDays, useMock])

  const totalEmployeeShare = weekSummary.length * Math.round(basePriceVal * (100 - subsidyRate) / 100)
  const totalExtras = weekSummary.reduce((s, i) => s + i.extrasTotal, 0)
  const totalCompanyShare = weekSummary.length * Math.round(basePriceVal * subsidyRate / 100)

  const handleValidate = async () => {
    if (useMock) {
      setConfirmationSuccess(true)
      setTimeout(() => {
        setShowConfirmation(false)
        setConfirmationSuccess(false)
      }, 2500)
      return
    }

    if (!activeMenu || !user?.user?.id) return
    setSaving(true)

    try {
      const userId = user.user.id
      const dayMap = selections.get(activeMenu.id)

      let planId: string = weeklyPlans.get(activeMenu.id)?.id || ""
      if (!planId) {
        const { data: newPlan, error: planErr } = await supabase
          .from("weekly_plans").insert({ user_id: userId, menu_id: activeMenu.id, status: "confirmed", confirmed_at: new Date().toISOString() })
          .select("id").single()
        if (planErr) throw planErr
        planId = newPlan.id
      } else {
        await supabase.from("weekly_plans").update({ status: "confirmed", confirmed_at: new Date().toISOString() }).eq("id", planId)
      }

      if (dayMap) {
        await supabase.from("weekly_plan_items").delete().eq("weekly_plan_id", planId)
        const items: Array<{ weekly_plan_id: string; day_of_week: number; dish_id: string; extras: ExtraItem[]; is_locked: boolean }> = []
        for (const [day, sel] of dayMap.entries()) {
          if (sel.dishId) {
            items.push({ weekly_plan_id: planId, day_of_week: day, dish_id: sel.dishId, extras: sel.extras, is_locked: isDayLocked(activeMenu.week_start, day) })
          }
        }
        if (items.length > 0) {
          const { error: itemErr } = await supabase.from("weekly_plan_items").insert(items)
          if (itemErr) throw itemErr
        }
      }

      // Create orders
      if (dayMap) {
        for (const [day, sel] of dayMap.entries()) {
          if (!sel.dishId) continue
          const orderDate = new Date(activeMenu.week_start + "T00:00:00")
          orderDate.setDate(orderDate.getDate() + day - 1)
          const extrasTotal = sel.extras.reduce((s: number, e: ExtraItem) => s + e.unit_price * e.quantity, 0)
          await supabase.from("orders").upsert({
            user_id: userId, dish_id: sel.dishId, site_id: profile?.site_id || null,
            order_date: orderDate.toISOString().split("T")[0], extras: sel.extras,
            status: "confirmed", total_price: basePriceVal + extrasTotal,
          }, { onConflict: "user_id,order_date" })
        }
      }

      setConfirmationSuccess(true)

      const { data: refreshedPlan } = await supabase
        .from("weekly_plans").select("*, items:weekly_plan_items(*, dish:dishes(*))")
        .eq("id", planId).single()
      if (refreshedPlan) {
        setWeeklyPlans(prev => { const next = new Map(prev); next.set(activeMenu.id, refreshedPlan); return next })
      }
    } catch (err) {
      console.error(err)
      toast({ title: "Erreur", description: "Impossible de valider le planning.", variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  const handleCancelDay = async () => {
    if (!cancelDayDialog || !cancelDayReason.trim()) return
    const { menuId, dayOfWeek } = cancelDayDialog
    const planData = weeklyPlans.get(menuId)
    if (!planData) return
    const item = planData.items?.find(i => i.day_of_week === dayOfWeek)
    if (!item) return

    try {
      if (!useMock) {
        await supabase.from("weekly_plan_items").update({ is_cancelled: true, cancel_reason: cancelDayReason }).eq("id", item.id)
        const menu = menus.find(m => m.id === menuId)
        if (menu && user?.user?.id) {
          const orderDate = new Date(menu.week_start + "T00:00:00")
          orderDate.setDate(orderDate.getDate() + dayOfWeek - 1)
          await supabase.from("orders").update({ status: "cancelled", special_instructions: cancelDayReason })
            .eq("user_id", user.user.id).eq("order_date", orderDate.toISOString().split("T")[0])
        }
      }
      setSelections(prev => {
        const next = new Map(prev)
        const dayMap = new Map(next.get(menuId) || new Map())
        dayMap.set(dayOfWeek, { dishId: null, extras: [] })
        next.set(menuId, dayMap)
        return next
      })
      toast({ title: "Repas annulé", description: `${DAY_LABELS[dayOfWeek]} annulé.` })
    } catch {
      toast({ title: "Erreur", description: "Impossible d'annuler.", variant: "destructive" })
    } finally {
      setCancelDayDialog(null)
      setCancelDayReason("")
    }
  }

  return {
    menus, activeMenu, loading, saving, activeWeekIdx, setActiveWeekIdx,
    activeDayOfWeek, setActiveDayOfWeek, workingDays, dayMenuItems,
    currentSelection, dayLocked, plan, planConfirmed, contract,
    selectDish, updateExtra, dayTotal, companyShareDay, employeeShareDay,
    weekProgress, weekSummary, totalEmployeeShare, totalExtras, totalCompanyShare,
    showConfirmation, setShowConfirmation, confirmationSuccess, setConfirmationSuccess,
    handleValidate, isDayLocked: (day: number) => activeMenu ? isDayLocked(activeMenu.week_start, day) : true,
    extrasOpen, setExtrasOpen, selections, basePriceVal, subsidyRate,
    cancelDayDialog, setCancelDayDialog, cancelDayReason, setCancelDayReason, handleCancelDay,
  }
}

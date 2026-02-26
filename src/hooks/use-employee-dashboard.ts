import { useEffect, useState } from "react"
import { useAuth } from "./use-auth"
import { supabase } from "@/lib/supabase"
import type { Order, Notification, WeeklyPlan, Dish, CompanyContract, Menu } from "@/lib/types"

// ── Mock data ──
const MOCK_DISHES: Record<string, Dish> = {
  garba: { id: "m1", name: "Garba", description: "Attiéké au thon frit, piment et oignon", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 0, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Garba_dish.jpg/640px-Garba_dish.jpg", created_at: "", updated_at: "" },
  poulet: { id: "m2", name: "Poulet braisé", description: "Poulet braisé aux épices, alloco et attiéké", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 0, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Braised_chicken.jpg/640px-Braised_chicken.jpg", created_at: "", updated_at: "" },
  kedjenou: { id: "m3", name: "Kédjenou de poulet", description: "Poulet mijoté aux légumes en cocotte", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Kedjenou.jpg/640px-Kedjenou.jpg", created_at: "", updated_at: "" },
  alloco: { id: "m4", name: "Alloco poisson", description: "Banane plantain frite avec poisson grillé", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Alloco.jpg/640px-Alloco.jpg", created_at: "", updated_at: "" },
}

const MOCK_TODAY_ORDER: Order & { dish?: Dish } = {
  id: "mock-order-1", user_id: "", dish_id: "m1", order_date: new Date().toISOString().split("T")[0],
  extras: [], status: "confirmed", total_price: 5000, company_share: 4500, employee_share: 500,
  ticket_used: false, created_at: "", updated_at: "",
  dish: MOCK_DISHES.garba,
}

const MOCK_RECENT_ORDERS: (Order & { dish?: Dish })[] = [
  { id: "mo1", user_id: "", dish_id: "m1", order_date: "2026-02-25", extras: [], status: "served", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: MOCK_DISHES.garba },
  { id: "mo2", user_id: "", dish_id: "m2", order_date: "2026-02-24", extras: [], status: "served", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: MOCK_DISHES.poulet },
  { id: "mo3", user_id: "", dish_id: "m3", order_date: "2026-02-21", extras: [], status: "served", total_price: 5500, company_share: 4500, employee_share: 1000, ticket_used: false, created_at: "", updated_at: "", dish: MOCK_DISHES.kedjenou },
]

const MOCK_NOTIFICATIONS: Notification[] = [
  { id: "n1", user_id: "", title: "Menu publié", message: "Le menu de la semaine prochaine est disponible !", type: "info", is_read: false, link: "/app/employee/menu", created_at: new Date().toISOString() },
  { id: "n2", user_id: "", title: "Commande confirmée", message: "Votre Garba est confirmé pour aujourd'hui.", type: "success", is_read: false, created_at: new Date(Date.now() - 3600_000).toISOString() },
]

interface DashboardData {
  todayOrder: (Order & { dish?: Dish }) | null
  recentOrders: (Order & { dish?: Dish })[]
  notifications: Notification[]
  unreadCount: number
  contract: CompanyContract | null
  weeklyPlan: WeeklyPlan | null
  currentMenu: Menu | null
  loading: boolean
  monthlySpent: number
}

export function useEmployeeDashboard(): DashboardData {
  const { user } = useAuth()
  const [todayOrder, setTodayOrder] = useState<(Order & { dish?: Dish }) | null>(null)
  const [recentOrders, setRecentOrders] = useState<(Order & { dish?: Dish })[]>([])
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [contract, setContract] = useState<CompanyContract | null>(null)
  const [weeklyPlan, setWeeklyPlan] = useState<WeeklyPlan | null>(null)
  const [currentMenu, setCurrentMenu] = useState<Menu | null>(null)
  const [loading, setLoading] = useState(true)
  const [monthlySpent, setMonthlySpent] = useState(0)

  const profile = user?.profile
  const todayStr = new Date().toISOString().split("T")[0]

  useEffect(() => {
    if (!user?.user?.id) {
      // Use mock data when not connected
      setTodayOrder(MOCK_TODAY_ORDER)
      setRecentOrders(MOCK_RECENT_ORDERS)
      setNotifications(MOCK_NOTIFICATIONS)
      setMonthlySpent(9500)
      setLoading(false)
      return
    }

    const fetchData = async () => {
      setLoading(true)
      const userId = user.user.id

      const [orderRes, recentRes, notifRes, contractRes, planRes, menuRes] = await Promise.all([
        supabase.from("orders").select("*, dish:dishes(*)").eq("user_id", userId).eq("order_date", todayStr).maybeSingle(),
        supabase.from("orders").select("*, dish:dishes(*)").eq("user_id", userId).order("order_date", { ascending: false }).limit(3),
        supabase.from("notifications").select("*").eq("user_id", userId).eq("is_read", false).order("created_at", { ascending: false }).limit(5),
        profile?.company_id
          ? supabase.from("company_contracts").select("*").eq("company_id", profile.company_id).eq("is_active", true).order("created_at", { ascending: false }).limit(1).maybeSingle()
          : Promise.resolve({ data: null }),
        supabase.from("weekly_plans").select("*, items:weekly_plan_items(*, dish:dishes(*))").eq("user_id", userId).order("created_at", { ascending: false }).limit(1).maybeSingle(),
        supabase.from("menus").select("*, items:menu_items(*, dish:dishes(*))").eq("is_published", true).gte("week_end", todayStr).order("week_start", { ascending: true }).limit(1).maybeSingle(),
      ])

      setTodayOrder(orderRes.data || null)
      setRecentOrders(recentRes.data || [])
      setNotifications(notifRes.data || [])
      setContract(contractRes.data || null)
      setWeeklyPlan(planRes.data || null)
      setCurrentMenu(menuRes.data || null)

      // Monthly spent
      const now = new Date()
      const startMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-01`
      const { data: monthOrders } = await supabase
        .from("orders").select("employee_share")
        .eq("user_id", userId).eq("status", "served")
        .gte("order_date", startMonth)
      setMonthlySpent(monthOrders?.reduce((s, o) => s + (o.employee_share || 0), 0) || 0)

      setLoading(false)
    }

    fetchData()
  }, [user?.user?.id, profile?.company_id, todayStr])

  return {
    todayOrder, recentOrders, notifications,
    unreadCount: notifications.length,
    contract, weeklyPlan, currentMenu, loading, monthlySpent,
  }
}

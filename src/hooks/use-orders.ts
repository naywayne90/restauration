import { useCallback, useEffect, useMemo, useState } from "react"
import { useAuth } from "./use-auth"
import { supabase } from "@/lib/supabase"
import { useToast } from "@/components/ui/use-toast"
import type { Order, Dish, OrderStatus } from "@/lib/types"

const MONTHS = [
  "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
  "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
]

// ── Mock data ──
const MOCK_ORDERS: (Order & { dish?: Dish })[] = [
  { id: "mo1", user_id: "", dish_id: "", order_date: "2026-02-25", extras: [], status: "served", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: { id: "d1", name: "Garba", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 0, created_at: "", updated_at: "", photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Garba_dish.jpg/640px-Garba_dish.jpg" } },
  { id: "mo2", user_id: "", dish_id: "", order_date: "2026-02-24", extras: [], status: "served", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: { id: "d2", name: "Poulet braisé", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 0, created_at: "", updated_at: "", photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Braised_chicken.jpg/640px-Braised_chicken.jpg" } },
  { id: "mo3", user_id: "", dish_id: "", order_date: "2026-02-21", extras: [{ dish_id: "e1", quantity: 1, unit_price: 500 }], status: "served", total_price: 5500, company_share: 4500, employee_share: 1000, ticket_used: false, created_at: "", updated_at: "", dish: { id: "d3", name: "Kédjenou de poulet", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, created_at: "", updated_at: "" } },
  { id: "mo4", user_id: "", dish_id: "", order_date: "2026-02-20", extras: [], status: "confirmed", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: { id: "d4", name: "Attiéké poisson", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, created_at: "", updated_at: "" } },
  { id: "mo5", user_id: "", dish_id: "", order_date: "2026-02-19", extras: [], status: "cancelled", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", special_instructions: "Absent pour raison personnelle", dish: { id: "d5", name: "Placali sauce djoumblé", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, created_at: "", updated_at: "" } },
  { id: "mo6", user_id: "", dish_id: "", order_date: "2026-02-18", extras: [], status: "served", total_price: 5000, company_share: 4500, employee_share: 500, ticket_used: false, created_at: "", updated_at: "", dish: { id: "d6", name: "Alloco poisson", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: false, sort_order: 0, created_at: "", updated_at: "" } },
]

const PAGE_SIZE = 20

export function useOrders() {
  const { user } = useAuth()
  const { toast } = useToast()
  const useMock = !user?.user?.id

  const [orders, setOrders] = useState<(Order & { dish?: Dish })[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [selectedMonth, setSelectedMonth] = useState(() => {
    const now = new Date()
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`
  })
  const [statusFilter, setStatusFilter] = useState("all")
  const [cancelDialog, setCancelDialog] = useState<string | null>(null) // orderId
  const [cancelReason, setCancelReason] = useState("")

  const [year, month] = selectedMonth.split("-").map(Number)

  const fetchOrders = useCallback(async (offset = 0, append = false) => {
    if (useMock) {
      const filtered = statusFilter === "all" ? MOCK_ORDERS : MOCK_ORDERS.filter(o => o.status === statusFilter)
      setOrders(filtered)
      setHasMore(false)
      setLoading(false)
      return
    }
    if (!user?.user?.id) return

    if (offset === 0) setLoading(true)
    else setLoadingMore(true)

    const startDate = `${year}-${String(month).padStart(2, "0")}-01`
    const endDate = new Date(year, month, 0).toISOString().split("T")[0]

    let query = supabase.from("orders").select("*, dish:dishes(*)")
      .eq("user_id", user.user.id)
      .gte("order_date", startDate).lte("order_date", endDate)
      .order("order_date", { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1)

    if (statusFilter !== "all") query = query.eq("status", statusFilter)

    const { data } = await query
    if (data) {
      if (append) setOrders(prev => [...prev, ...data])
      else setOrders(data)
      setHasMore(data.length === PAGE_SIZE)
    }
    setLoading(false)
    setLoadingMore(false)
  }, [user?.user?.id, year, month, statusFilter, useMock])

  useEffect(() => {
    setOrders([])
    setHasMore(true)
    fetchOrders(0, false)
  }, [fetchOrders])

  const loadMore = () => {
    if (!loadingMore && hasMore) fetchOrders(orders.length, true)
  }

  const handleCancelOrder = async () => {
    if (!cancelDialog || !cancelReason.trim()) return
    try {
      if (!useMock) {
        await supabase.from("orders")
          .update({ status: "cancelled", special_instructions: cancelReason })
          .eq("id", cancelDialog)
      }
      setOrders(prev => prev.map(o => o.id === cancelDialog ? { ...o, status: "cancelled" as OrderStatus, special_instructions: cancelReason } : o))
      toast({ title: "Commande annulée" })
    } catch {
      toast({ title: "Erreur", description: "Impossible d'annuler.", variant: "destructive" })
    } finally {
      setCancelDialog(null)
      setCancelReason("")
    }
  }

  const summary = useMemo(() => {
    const total = orders.length
    const served = orders.filter(o => o.status === "served").length
    const cancelled = orders.filter(o => o.status === "cancelled").length
    const totalSpent = orders.filter(o => o.status === "served").reduce((sum, o) => sum + o.employee_share, 0)
    const totalCompany = orders.filter(o => o.status === "served").reduce((sum, o) => sum + o.company_share, 0)
    return { total, served, cancelled, totalSpent, totalCompany }
  }, [orders])

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

  return {
    orders, loading, loadingMore, hasMore, loadMore,
    selectedMonth, setSelectedMonth, statusFilter, setStatusFilter,
    summary, monthOptions,
    cancelDialog, setCancelDialog, cancelReason, setCancelReason, handleCancelOrder,
  }
}

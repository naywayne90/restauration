import { useEffect, useState } from "react"
import { useAuth } from "./use-auth"
import { supabase } from "@/lib/supabase"
import type { Order, QRCode, QRScan, Dish } from "@/lib/types"

// ── Mock data ──
const MOCK_QR: QRCode = {
  id: "qr-mock-1", user_id: "", order_id: "mock-order-1",
  code: "MILYS-2026-02-26-EMP001-A7X9",
  is_used: false, expires_at: new Date(new Date().setHours(14, 0, 0)).toISOString(),
  created_at: new Date().toISOString(),
}

const MOCK_ORDER: Order & { dish?: Dish } = {
  id: "mock-order-1", user_id: "", dish_id: "m1",
  order_date: new Date().toISOString().split("T")[0],
  extras: [], status: "confirmed", total_price: 5000, company_share: 4500, employee_share: 500,
  ticket_used: false, created_at: "", updated_at: "",
  dish: { id: "m1", name: "Garba", description: "Attiéké au thon frit", category: "ivoirien", price: 5000, is_available: true, is_starter: false, is_extra: false, is_vegetarian: false, is_vegan: false, is_featured: true, sort_order: 0, photo_url: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Garba_dish.jpg/640px-Garba_dish.jpg", created_at: "", updated_at: "" },
}

const MOCK_SCANS: QRScan[] = [
  { id: "sc1", qr_code_id: "qr-mock-1", scanned_by: "", scan_type: "qr", result: "success", scanned_at: new Date(Date.now() - 86400_000).toISOString() },
  { id: "sc2", qr_code_id: "qr-prev", scanned_by: "", scan_type: "qr", result: "success", scanned_at: new Date(Date.now() - 172800_000).toISOString() },
]

export function useQRCode() {
  const { user } = useAuth()
  const useMock = !user?.user?.id
  const [todayOrder, setTodayOrder] = useState<(Order & { dish?: Dish }) | null>(null)
  const [qrCode, setQrCode] = useState<QRCode | null>(null)
  const [scanHistory, setScanHistory] = useState<QRScan[]>([])
  const [loading, setLoading] = useState(true)

  const todayStr = new Date().toISOString().split("T")[0]

  useEffect(() => {
    if (useMock) {
      setTodayOrder(MOCK_ORDER)
      setQrCode(MOCK_QR)
      setScanHistory(MOCK_SCANS)
      setLoading(false)
      return
    }

    const fetchData = async () => {
      setLoading(true)
      const userId = user!.user.id

      const { data: orderData } = await supabase
        .from("orders").select("*, dish:dishes(*)")
        .eq("user_id", userId).eq("order_date", todayStr)
        .in("status", ["confirmed"]).maybeSingle()

      if (orderData) {
        setTodayOrder(orderData)
        const { data: qrData } = await supabase
          .from("qr_codes").select("*")
          .eq("order_id", orderData.id).maybeSingle()
        if (qrData) setQrCode(qrData)
      }

      const { data: qrCodes } = await supabase
        .from("qr_codes").select("id").eq("user_id", userId)
        .order("created_at", { ascending: false }).limit(10)

      if (qrCodes && qrCodes.length > 0) {
        const qrIds = qrCodes.map((q: { id: string }) => q.id)
        const { data: scans } = await supabase
          .from("qr_scans").select("*").in("qr_code_id", qrIds)
          .order("scanned_at", { ascending: false }).limit(5)
        if (scans) setScanHistory(scans)
      }

      setLoading(false)
    }
    fetchData()
  }, [user?.user?.id, todayStr, useMock])

  // Realtime
  useEffect(() => {
    if (!qrCode?.id || useMock) return
    const channel = supabase.channel("qr-scan-rt")
      .on("postgres_changes", { event: "INSERT", schema: "public", table: "qr_scans", filter: `qr_code_id=eq.${qrCode.id}` }, (payload) => {
        if (payload.new) {
          setScanHistory(prev => [payload.new as QRScan, ...prev])
          if ((payload.new as QRScan).result === "success") {
            setQrCode(prev => prev ? { ...prev, is_used: true } : prev)
          }
        }
      }).subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [qrCode?.id, useMock])

  return { todayOrder, qrCode, scanHistory, loading }
}

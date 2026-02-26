import { useEffect, useState } from "react"
import { Clock, CheckCircle2, XCircle, AlertCircle, History, Utensils } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"
import { Separator } from "@/components/ui/separator"
import { useAuth } from "@/hooks/use-auth"
import { supabase } from "@/lib/supabase"
import type { Order, QRCode, QRScan, Dish } from "@/lib/types"
import { QR_VALID_START, QR_VALID_END, CURRENCY } from "@/lib/constants"
import { QRCodeDisplay } from "@/components/shared/QRCodeDisplay"
import { OrderStatusBadge } from "@/components/shared/StatusBadge"
import { PriceDisplay } from "@/components/shared/PriceDisplay"

export function MyQRCode() {
  const { user } = useAuth()
  const [todayOrder, setTodayOrder] = useState<(Order & { dish?: Dish }) | null>(null)
  const [qrCode, setQrCode] = useState<QRCode | null>(null)
  const [scanHistory, setScanHistory] = useState<QRScan[]>([])
  const [loading, setLoading] = useState(true)

  const profile = user?.profile
  const todayStr = new Date().toISOString().split("T")[0]

  useEffect(() => {
    if (!user?.user?.id) return

    const fetchData = async () => {
      setLoading(true)
      const userId = user.user.id

      const { data: orderData } = await supabase
        .from("orders")
        .select("*, dish:dishes(*)")
        .eq("user_id", userId)
        .eq("order_date", todayStr)
        .in("status", ["confirmed"])
        .maybeSingle()

      if (orderData) {
        setTodayOrder(orderData)

        const { data: qrData } = await supabase
          .from("qr_codes")
          .select("*")
          .eq("order_id", orderData.id)
          .maybeSingle()

        if (qrData) setQrCode(qrData)
      }

      const { data: qrCodes } = await supabase
        .from("qr_codes")
        .select("id")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(10)

      if (qrCodes && qrCodes.length > 0) {
        const qrIds = qrCodes.map((q: { id: string }) => q.id)
        const { data: scans } = await supabase
          .from("qr_scans")
          .select("*")
          .in("qr_code_id", qrIds)
          .order("scanned_at", { ascending: false })
          .limit(10)

        if (scans) setScanHistory(scans)
      }

      setLoading(false)
    }

    fetchData()
  }, [user?.user?.id, todayStr])

  // Realtime scan detection
  useEffect(() => {
    if (!qrCode?.id) return

    const channel = supabase
      .channel("qr-scan-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "qr_scans",
          filter: `qr_code_id=eq.${qrCode.id}`,
        },
        (payload) => {
          if (payload.new) {
            setScanHistory(prev => [payload.new as QRScan, ...prev])
            if ((payload.new as QRScan).result === "success") {
              setQrCode(prev => prev ? { ...prev, is_used: true } : prev)
            }
          }
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [qrCode?.id])

  const now = new Date()
  const [startH, startM] = QR_VALID_START.split(":").map(Number)
  const [endH, endM] = QR_VALID_END.split(":").map(Number)
  const currentMinutes = now.getHours() * 60 + now.getMinutes()
  const startMinutes = startH * 60 + startM
  const endMinutes = endH * 60 + endM
  const isValidTime = currentMinutes >= startMinutes && currentMinutes <= endMinutes
  const isQrUsed = qrCode?.is_used || false

  if (loading) {
    return (
      <div className="space-y-6 p-4 md:p-6 max-w-2xl mx-auto">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-80 w-full rounded-2xl" />
        <Skeleton className="h-32 w-full rounded-xl" />
      </div>
    )
  }

  if (!todayOrder) {
    return (
      <div className="flex flex-col items-center justify-center py-20 px-4 text-center max-w-md mx-auto">
        <div className="h-20 w-20 rounded-full bg-slate-100 flex items-center justify-center mb-4">
          <AlertCircle className="h-10 w-10 text-slate-400" />
        </div>
        <h2 className="text-lg font-semibold text-slate-900 mb-2">Pas de QR code aujourd'hui</h2>
        <p className="text-sm text-slate-500">
          Vous n'avez pas de commande confirmee pour aujourd'hui.
          Planifiez vos repas depuis le menu de la semaine.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6 p-4 md:p-6 max-w-2xl mx-auto">
      <div>
        <h1 className="text-2xl font-bold text-slate-900">Mon QR code</h1>
        <p className="text-slate-500 text-sm mt-1">Presentez ce code au point de distribution</p>
      </div>

      <Card className="border-2 border-orange-200">
        <CardContent className="pt-6 flex flex-col items-center gap-4">
          <div className="text-center">
            <p className="text-sm font-semibold text-slate-700">{profile?.full_name}</p>
            <p className="text-xs text-slate-400">{profile?.company?.name}</p>
          </div>

          {qrCode ? (
            <QRCodeDisplay
              payload={{
                code: qrCode.code,
                orderId: todayOrder.id,
                userId: user!.user.id,
                date: todayStr,
              }}
              size={280}
              validStart={QR_VALID_START}
              validEnd={QR_VALID_END}
            />
          ) : (
            <div className="flex flex-col items-center gap-2 py-8">
              <AlertCircle className="h-12 w-12 text-amber-500" />
              <p className="text-sm text-slate-500">QR code en cours de generation...</p>
            </div>
          )}

          <div className="flex items-center gap-2 flex-wrap justify-center">
            {isQrUsed ? (
              <Badge className="bg-green-100 text-green-700 hover:bg-green-100 gap-1">
                <CheckCircle2 className="h-3 w-3" /> Deja scanne
              </Badge>
            ) : isValidTime ? (
              <Badge className="bg-emerald-100 text-emerald-700 hover:bg-emerald-100 gap-1">
                <CheckCircle2 className="h-3 w-3" /> Valide maintenant
              </Badge>
            ) : currentMinutes < startMinutes ? (
              <Badge className="bg-amber-100 text-amber-700 hover:bg-amber-100 gap-1">
                <Clock className="h-3 w-3" /> Valide des {QR_VALID_START}
              </Badge>
            ) : (
              <Badge className="bg-red-100 text-red-700 hover:bg-red-100 gap-1">
                <XCircle className="h-3 w-3" /> Expire (apres {QR_VALID_END})
              </Badge>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base flex items-center gap-2">
            <Utensils className="h-4 w-4 text-orange-500" />
            Commande du jour
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-center gap-3">
            {todayOrder.dish?.photo_url && (
              <img src={todayOrder.dish.photo_url} alt={todayOrder.dish.name}
                className="h-16 w-16 rounded-lg object-cover shrink-0" />
            )}
            <div className="flex-1">
              <p className="font-semibold text-slate-900">{todayOrder.dish?.name}</p>
              <OrderStatusBadge status={todayOrder.status} className="mt-1" />
            </div>
            <PriceDisplay amount={todayOrder.total_price} highlight />
          </div>

          {todayOrder.extras.length > 0 && (
            <>
              <Separator />
              <div>
                <p className="text-xs text-slate-500 mb-1">Extras</p>
                {todayOrder.extras.map((extra, i) => (
                  <div key={i} className="flex justify-between text-sm text-slate-600">
                    <span>x{extra.quantity}</span>
                    <span>+{(extra.unit_price * extra.quantity).toLocaleString("fr-CI")} {CURRENCY}</span>
                  </div>
                ))}
              </div>
            </>
          )}

          <Separator />
          <div className="space-y-1">
            <div className="flex justify-between text-sm">
              <span className="text-slate-500">Total</span>
              <span className="font-semibold">{todayOrder.total_price.toLocaleString("fr-CI")} {CURRENCY}</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-green-600">Part entreprise</span>
              <span className="text-green-600">-{todayOrder.company_share.toLocaleString("fr-CI")} {CURRENCY}</span>
            </div>
            <div className="flex justify-between text-sm font-bold border-t pt-1">
              <span className="text-orange-600">Votre part</span>
              <span className="text-orange-600">{todayOrder.employee_share.toLocaleString("fr-CI")} {CURRENCY}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="bg-amber-50 border-amber-200">
        <CardContent className="pt-4 pb-4">
          <p className="text-sm text-amber-800 font-medium">Comment utiliser votre QR code ?</p>
          <ul className="mt-2 space-y-1">
            {[
              `Presentez-le entre ${QR_VALID_START} et ${QR_VALID_END} au point de distribution.`,
              "Le caissier scannera votre code pour valider votre repas.",
              "Le montant sera facture a votre entreprise (hors extras).",
            ].map((tip, i) => (
              <li key={i} className="text-xs text-amber-700 flex items-start gap-2">
                <span className="font-bold mt-0.5">{i + 1}.</span>
                {tip}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>

      {scanHistory.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base flex items-center gap-2">
              <History className="h-4 w-4 text-slate-500" />
              Historique des scans
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="divide-y divide-slate-100">
              {scanHistory.map((scan) => (
                <div key={scan.id} className="flex items-center gap-3 px-4 py-3">
                  {scan.result === "success" ? (
                    <CheckCircle2 className="h-5 w-5 text-green-500 shrink-0" />
                  ) : (
                    <XCircle className="h-5 w-5 text-red-500 shrink-0" />
                  )}
                  <div className="flex-1">
                    <p className="text-sm text-slate-700">
                      {scan.result === "success" ? "Scan reussi" :
                       scan.result === "already_used" ? "Deja utilise" :
                       scan.result === "expired" ? "Expire" : "Non trouve"}
                    </p>
                    <p className="text-xs text-slate-400">
                      {new Date(scan.scanned_at).toLocaleDateString("fr-FR", {
                        day: "numeric", month: "short", hour: "2-digit", minute: "2-digit"
                      })}
                    </p>
                  </div>
                  <Badge variant="outline" className="text-xs">{scan.scan_type}</Badge>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

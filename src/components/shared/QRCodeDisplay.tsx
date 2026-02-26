import { QRCodeSVG } from "qrcode.react"
import { cn } from "@/lib/utils"
import { Maximize2, Minimize2 } from "lucide-react"
import { useState } from "react"
import { Button } from "@/components/ui/button"

interface QRCodePayload {
  code: string
  orderId: string
  userId: string
  date: string
}

interface QRCodeDisplayProps {
  payload: QRCodePayload
  size?: number
  className?: string
  validStart?: string
  validEnd?: string
}

export function QRCodeDisplay({
  payload,
  size = 300,
  className,
  validStart = "11:00",
  validEnd = "14:00",
}: QRCodeDisplayProps) {
  const [fullscreen, setFullscreen] = useState(false)
  const jsonValue = JSON.stringify(payload)

  if (fullscreen) {
    return (
      <div
        className="fixed inset-0 z-50 bg-white flex flex-col items-center justify-center"
        onClick={() => setFullscreen(false)}
      >
        <QRCodeSVG
          value={jsonValue}
          size={Math.min(window.innerWidth - 40, 400)}
          level="H"
          includeMargin
        />
        <p className="mt-4 text-sm text-slate-500">
          Valide {validStart} - {validEnd}
        </p>
        <Button
          variant="outline"
          size="sm"
          className="mt-4 gap-2"
          onClick={() => setFullscreen(false)}
        >
          <Minimize2 className="h-4 w-4" />
          Fermer
        </Button>
      </div>
    )
  }

  return (
    <div className={cn("flex flex-col items-center", className)}>
      <div className="relative bg-white p-4 rounded-2xl border-2 border-slate-200 shadow-sm">
        <QRCodeSVG
          value={jsonValue}
          size={size}
          level="H"
          includeMargin
        />
        <button
          type="button"
          onClick={() => setFullscreen(true)}
          className="absolute top-2 right-2 h-8 w-8 rounded-full bg-slate-100 hover:bg-slate-200 flex items-center justify-center transition-colors"
        >
          <Maximize2 className="h-4 w-4 text-slate-600" />
        </button>
      </div>
      <p className="mt-2 text-xs text-slate-400 font-mono">{payload.code}</p>
    </div>
  )
}

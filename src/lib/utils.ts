import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("fr-CI", {
    style: "currency",
    currency: "XOF",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount)
}

export function formatDate(date: string | Date, format?: string): string {
  const d = typeof date === "string" ? new Date(date) : date
  if (format === "short") {
    return new Intl.DateTimeFormat("fr-CI", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    }).format(d)
  }
  if (format === "time") {
    return new Intl.DateTimeFormat("fr-CI", {
      hour: "2-digit",
      minute: "2-digit",
    }).format(d)
  }
  return new Intl.DateTimeFormat("fr-CI", {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(d)
}

export function getInitials(name: string): string {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2)
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str
  return str.slice(0, length) + "…"
}

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

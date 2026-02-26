import { Navigate, Route, Routes } from "react-router-dom"
import { useAuth } from "@/hooks/use-auth"
import type { UserRole } from "@/lib/types"
import { PageLoader } from "@/components/shared/LoadingSpinner"
import { ForbiddenPage } from "@/components/shared/ForbiddenPage"
import { AdminLayout } from "@/components/layout/AdminLayout"
import { EmployeeLayout } from "@/components/layout/EmployeeLayout"
import { PublicLayout } from "@/components/layout/PublicLayout"

// Auth pages
import { LoginPage } from "@/pages/auth/LoginPage"
import { ForgotPasswordPage } from "@/pages/auth/ForgotPasswordPage"

// Admin pages
import { AdminDashboard } from "@/pages/admin/Dashboard"
import { Companies } from "@/pages/admin/Companies"
import { Employees } from "@/pages/admin/Employees"
import { Dishes } from "@/pages/admin/Dishes"
import { Menus } from "@/pages/admin/Menus"
import { Orders } from "@/pages/admin/Orders"
import { Invoices } from "@/pages/admin/Invoices"
import { Deliveries } from "@/pages/admin/Deliveries"
import { Suppliers } from "@/pages/admin/Suppliers"
import { Stock } from "@/pages/admin/Stock"
import { Settings } from "@/pages/admin/Settings"

// Kitchen pages
import { DailyProduction } from "@/pages/kitchen/DailyProduction"
import { StockAlerts } from "@/pages/kitchen/StockAlerts"

// Cashier pages
import { ScanQR } from "@/pages/cashier/ScanQR"
import { DailyReport } from "@/pages/cashier/DailyReport"

// Employee pages
import { EmployeeDashboard } from "@/pages/employee/Dashboard"
import { WeeklyMenu } from "@/pages/employee/WeeklyMenu"
import { MyOrders } from "@/pages/employee/MyOrders"
import { MyQRCode } from "@/pages/employee/MyQRCode"
import { Profile } from "@/pages/employee/Profile"

// Public pages
import { LandingPage } from "@/pages/public/LandingPage"
import { HowItWorks } from "@/pages/public/HowItWorks"
import { ForCompanies } from "@/pages/public/ForCompanies"
import { Contact } from "@/pages/public/Contact"

import { ROLE_HOME_ROUTES } from "@/lib/constants"

// ─── Role groups ────────────────────────────────────────────────────────────

const ADMIN_ALLOWED: UserRole[] = [
  "superadmin", "milys_admin", "milys_logistics", "company_admin",
]
const KITCHEN_ALLOWED: UserRole[] = [
  "superadmin", "milys_admin", "milys_kitchen",
]
const CASHIER_ALLOWED: UserRole[] = [
  "superadmin", "milys_admin", "milys_cashier", "company_cashier", "third_party_cashier",
]
const EMPLOYEE_ALLOWED: UserRole[] = [
  "superadmin", "milys_admin", "employee",
]

// ─── Route guards ───────────────────────────────────────────────────────────

function ProtectedRoute({
  children,
  allowedRoles,
}: {
  children: React.ReactNode
  allowedRoles?: UserRole[]
}) {
  const { user, isLoading, hasAnyRole } = useAuth()

  if (isLoading) return <PageLoader />
  if (!user) return <Navigate to="/login" replace />

  if (allowedRoles && !hasAnyRole(allowedRoles)) {
    return <ForbiddenPage />
  }

  return <>{children}</>
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth()

  if (isLoading) return <PageLoader />
  if (user) {
    const role = user.roles[0]
    const redirect = ROLE_HOME_ROUTES[role] || "/app/employee/dashboard"
    return <Navigate to={redirect} replace />
  }
  return <>{children}</>
}

// ─── App routes ─────────────────────────────────────────────────────────────

export default function App() {
  return (
    <Routes>
      {/* Public marketing pages — /gourmet/* */}
      <Route element={<PublicLayout />}>
        <Route path="/gourmet" element={<LandingPage />} />
        <Route path="/gourmet/entreprises" element={<ForCompanies />} />
        <Route path="/gourmet/comment-ca-marche" element={<HowItWorks />} />
        <Route path="/gourmet/contact" element={<Contact />} />
      </Route>

      {/* Auth pages */}
      <Route
        path="/login"
        element={
          <PublicRoute>
            <LoginPage />
          </PublicRoute>
        }
      />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />

      {/* Admin routes — /app/admin/* */}
      <Route
        element={
          <ProtectedRoute allowedRoles={ADMIN_ALLOWED}>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/app/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/app/admin/companies" element={<Companies />} />
        <Route path="/app/admin/employees" element={<Employees />} />
        <Route path="/app/admin/dishes" element={<Dishes />} />
        <Route path="/app/admin/menus" element={<Menus />} />
        <Route path="/app/admin/orders" element={<Orders />} />
        <Route path="/app/admin/invoices" element={<Invoices />} />
        <Route path="/app/admin/deliveries" element={<Deliveries />} />
        <Route path="/app/admin/suppliers" element={<Suppliers />} />
        <Route path="/app/admin/stock" element={<Stock />} />
        <Route path="/app/admin/settings" element={<Settings />} />
      </Route>

      {/* Kitchen routes — /app/kitchen/* */}
      <Route
        element={
          <ProtectedRoute allowedRoles={KITCHEN_ALLOWED}>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/app/kitchen/production" element={<DailyProduction />} />
        <Route path="/app/kitchen/stock" element={<StockAlerts />} />
      </Route>

      {/* Cashier routes — /app/cashier/* */}
      <Route
        element={
          <ProtectedRoute allowedRoles={CASHIER_ALLOWED}>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/app/cashier/scan" element={<ScanQR />} />
        <Route path="/app/cashier/report" element={<DailyReport />} />
      </Route>

      {/* Employee routes — /app/employee/* */}
      <Route
        element={
          <ProtectedRoute allowedRoles={EMPLOYEE_ALLOWED}>
            <EmployeeLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/app/employee/dashboard" element={<EmployeeDashboard />} />
        <Route path="/app/employee/menu" element={<WeeklyMenu />} />
        <Route path="/app/employee/orders" element={<MyOrders />} />
        <Route path="/app/employee/qrcode" element={<MyQRCode />} />
        <Route path="/app/employee/profile" element={<Profile />} />
      </Route>

      {/* Redirects */}
      <Route path="/" element={<Navigate to="/gourmet" replace />} />
      <Route path="*" element={<Navigate to="/gourmet" replace />} />
    </Routes>
  )
}

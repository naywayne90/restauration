import { Navigate, Route, Routes } from "react-router-dom"
import { useAuth } from "@/hooks/use-auth"
import { PageLoader } from "@/components/shared/LoadingSpinner"
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

// ─── Route guard ──────────────────────────────────────────────────────────────

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth()

  if (isLoading) return <PageLoader />
  if (!user) return <Navigate to="/login" replace />
  return <>{children}</>
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { user, isLoading } = useAuth()

  if (isLoading) return <PageLoader />
  if (user) {
    const role = user.roles[0]
    const redirect = ROLE_HOME_ROUTES[role] || "/employee/dashboard"
    return <Navigate to={redirect} replace />
  }
  return <>{children}</>
}

// ─── App routes ───────────────────────────────────────────────────────────────

export default function App() {
  return (
    <Routes>
      {/* Public marketing pages */}
      <Route element={<PublicLayout />}>
        <Route path="/" element={<LandingPage />} />
        <Route path="/comment-ca-marche" element={<HowItWorks />} />
        <Route path="/entreprises" element={<ForCompanies />} />
        <Route path="/contact" element={<Contact />} />
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

      {/* Admin / Kitchen / Cashier — AdminLayout */}
      <Route
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        {/* Admin routes */}
        <Route path="/admin/dashboard" element={<AdminDashboard />} />
        <Route path="/admin/companies" element={<Companies />} />
        <Route path="/admin/employees" element={<Employees />} />
        <Route path="/admin/dishes" element={<Dishes />} />
        <Route path="/admin/menus" element={<Menus />} />
        <Route path="/admin/orders" element={<Orders />} />
        <Route path="/admin/invoices" element={<Invoices />} />
        <Route path="/admin/deliveries" element={<Deliveries />} />
        <Route path="/admin/settings" element={<Settings />} />

        {/* Kitchen routes */}
        <Route path="/kitchen/production" element={<DailyProduction />} />
        <Route path="/kitchen/stock" element={<StockAlerts />} />

        {/* Cashier routes */}
        <Route path="/cashier/scan" element={<ScanQR />} />
        <Route path="/cashier/report" element={<DailyReport />} />
      </Route>

      {/* Employee — EmployeeLayout */}
      <Route
        element={
          <ProtectedRoute>
            <EmployeeLayout />
          </ProtectedRoute>
        }
      >
        <Route path="/employee/dashboard" element={<EmployeeDashboard />} />
        <Route path="/employee/menu" element={<WeeklyMenu />} />
        <Route path="/employee/orders" element={<MyOrders />} />
        <Route path="/employee/qrcode" element={<MyQRCode />} />
        <Route path="/employee/profile" element={<Profile />} />
      </Route>

      {/* Default redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

import type { UserRole } from "@/lib/types";

// ---------------------------------------------------------------------------
// French display labels for each role
// ---------------------------------------------------------------------------

export const ROLE_LABELS: Record<UserRole, string> = {
  superadmin: "Super Administrateur",
  milys_admin: "Admin MILY'S",
  milys_kitchen: "Cuisine",
  milys_logistics: "Logistique",
  milys_cashier: "Caissier MILY'S",
  company_admin: "Admin Entreprise",
  company_cashier: "Caissier Entreprise",
  third_party_cashier: "Caissier Tiers",
  employee: "Employ\u00e9",
};

// ---------------------------------------------------------------------------
// Default redirect path after login, per role
// ---------------------------------------------------------------------------

export const ROLE_REDIRECT: Record<UserRole, string> = {
  superadmin:          "/app/admin/dashboard",
  milys_admin:         "/app/admin/dashboard",
  milys_kitchen:       "/app/kitchen/production",
  milys_logistics:     "/app/admin/deliveries",
  milys_cashier:       "/app/cashier/scan",
  company_admin:       "/app/admin/companies",
  company_cashier:     "/app/cashier/scan",
  third_party_cashier: "/app/cashier/scan",
  employee:            "/app/employee/dashboard",
};

// ---------------------------------------------------------------------------
// Roles that can access /app/admin/* routes
// ---------------------------------------------------------------------------

export const ADMIN_ROLES: UserRole[] = [
  "superadmin",
  "milys_admin",
  "milys_logistics",
  "company_admin",
];

// ---------------------------------------------------------------------------
// Priority order — highest privilege first
// ---------------------------------------------------------------------------

const ROLE_PRIORITY: UserRole[] = [
  "superadmin",
  "milys_admin",
  "milys_kitchen",
  "milys_logistics",
  "milys_cashier",
  "company_admin",
  "company_cashier",
  "third_party_cashier",
  "employee",
];

/**
 * Given a list of roles, return the default redirect path for the
 * highest-priority role the user holds.  Falls back to the employee
 * dashboard when no roles are matched.
 */
export function getDefaultRedirect(roles: UserRole[]): string {
  for (const role of ROLE_PRIORITY) {
    if (roles.includes(role)) {
      return ROLE_REDIRECT[role];
    }
  }
  return ROLE_REDIRECT.employee;
}

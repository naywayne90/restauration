import type { User } from "@supabase/supabase-js";

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

export type UserRole =
  | "superadmin"
  | "milys_admin"
  | "milys_kitchen"
  | "milys_logistics"
  | "milys_cashier"
  | "company_admin"
  | "company_cashier"
  | "third_party_cashier"
  | "employee";

// ---------------------------------------------------------------------------
// Profile (mirrors the `profiles` table in Supabase)
// ---------------------------------------------------------------------------

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  phone: string | null;
  avatar_url: string | null;
  company_id: string | null;
  site_id: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// ---------------------------------------------------------------------------
// Authenticated user with their profile and roles
// ---------------------------------------------------------------------------

export interface UserWithProfile {
  user: User;
  profile: Profile | null;
  roles: UserRole[];
}

// ---------------------------------------------------------------------------
// Auth context value exposed via React context
// ---------------------------------------------------------------------------

export interface AuthContextType {
  user: UserWithProfile | null;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  hasRole: (role: UserRole) => boolean;
  hasAnyRole: (roles: UserRole[]) => boolean;
}

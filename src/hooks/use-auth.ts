"use client";

import { useContext } from "react";
import { AuthContext } from "@/contexts/auth-context";

/**
 * Convenience hook that returns the current AuthContext value.
 *
 * Must be used inside an `<AuthProvider>`.  Throws an error if
 * the context is undefined (i.e. used outside the provider tree).
 */
export function useAuth() {
  const context = useContext(AuthContext);

  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }

  return context;
}

"use client";

import {
  createContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { createClient } from "@/utils/supabase/client";
import type {
  AuthContextType,
  Profile,
  UserRole,
  UserWithProfile,
} from "@/lib/types";

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserWithProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const supabase = useMemo(() => createClient(), []);

  // -----------------------------------------------------------------------
  // Fetch profile + roles for a given user id / email
  // -----------------------------------------------------------------------
  const fetchUserData = useCallback(
    async (userId: string): Promise<UserWithProfile | null> => {
      const {
        data: { user: supabaseUser },
      } = await supabase.auth.getUser();

      if (!supabaseUser) return null;

      // Fetch profile
      const { data: profile } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", userId)
        .single<Profile>();

      // Fetch roles
      const { data: roleRows } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", userId);

      const roles: UserRole[] =
        roleRows?.map((r: { role: string }) => r.role as UserRole) ?? [];

      return {
        user: supabaseUser,
        profile: profile ?? null,
        roles,
      };
    },
    [supabase],
  );

  // -----------------------------------------------------------------------
  // Listen to auth state changes
  // -----------------------------------------------------------------------
  useEffect(() => {
    // Fetch data for the current session on mount
    const initializeAuth = async () => {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession();

        if (session?.user) {
          const userData = await fetchUserData(session.user.id);
          setUser(userData);
        }
      } catch (error) {
        console.error("Error initializing auth:", error);
      } finally {
        setIsLoading(false);
      }
    };

    initializeAuth();

    // Subscribe to future auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "SIGNED_IN" && session?.user) {
        const userData = await fetchUserData(session.user.id);
        setUser(userData);
        setIsLoading(false);
      } else if (event === "SIGNED_OUT") {
        setUser(null);
        setIsLoading(false);
      } else if (event === "TOKEN_REFRESHED" && session?.user) {
        const userData = await fetchUserData(session.user.id);
        setUser(userData);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [supabase, fetchUserData]);

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------
  const signIn = useCallback(
    async (email: string, password: string) => {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw error;
      }
    },
    [supabase],
  );

  const signOut = useCallback(async () => {
    const { error } = await supabase.auth.signOut();

    if (error) {
      throw error;
    }

    setUser(null);
  }, [supabase]);

  // -----------------------------------------------------------------------
  // Role helpers
  // -----------------------------------------------------------------------
  const hasRole = useCallback(
    (role: UserRole): boolean => {
      return user?.roles.includes(role) ?? false;
    },
    [user],
  );

  const hasAnyRole = useCallback(
    (roles: UserRole[]): boolean => {
      return roles.some((role) => user?.roles.includes(role));
    },
    [user],
  );

  // -----------------------------------------------------------------------
  // Memoised context value
  // -----------------------------------------------------------------------
  const value = useMemo<AuthContextType>(
    () => ({
      user,
      isLoading,
      signIn,
      signOut,
      hasRole,
      hasAnyRole,
    }),
    [user, isLoading, signIn, signOut, hasRole, hasAnyRole],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

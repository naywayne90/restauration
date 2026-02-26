import {
  createContext,
  useCallback,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react"
import { supabase } from "@/lib/supabase"
import type { Profile, UserRole } from "@/lib/types"
import type { User } from "@supabase/supabase-js"

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface UserWithProfile {
  user: User
  profile: Profile | null
  roles: UserRole[]
}

export interface AuthContextType {
  user: UserWithProfile | null
  isLoading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  hasRole: (role: UserRole) => boolean
  hasAnyRole: (roles: UserRole[]) => boolean
}

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

export const AuthContext = createContext<AuthContextType | undefined>(undefined)

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserWithProfile | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const fetchUserData = useCallback(
    async (userId: string): Promise<UserWithProfile | null> => {
      const {
        data: { user: supabaseUser },
      } = await supabase.auth.getUser()

      if (!supabaseUser) return null

      const { data: profile } = await supabase
        .from("profiles")
        .select("*, company:companies(*), site:company_sites(*)")
        .eq("user_id", userId)
        .single<Profile>()

      const { data: roleRows } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", userId)

      const roles: UserRole[] =
        roleRows?.map((r: { role: string }) => r.role as UserRole) ?? []

      return {
        user: supabaseUser,
        profile: profile ?? null,
        roles,
      }
    },
    []
  )

  useEffect(() => {
    const initializeAuth = async () => {
      try {
        const {
          data: { session },
        } = await supabase.auth.getSession()

        if (session?.user) {
          const userData = await fetchUserData(session.user.id)
          setUser(userData)
        }
      } catch (error) {
        console.error("Error initializing auth:", error)
      } finally {
        setIsLoading(false)
      }
    }

    initializeAuth()

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "SIGNED_IN" && session?.user) {
        const userData = await fetchUserData(session.user.id)
        setUser(userData)
        setIsLoading(false)
      } else if (event === "SIGNED_OUT") {
        setUser(null)
        setIsLoading(false)
      } else if (event === "TOKEN_REFRESHED" && session?.user) {
        const userData = await fetchUserData(session.user.id)
        setUser(userData)
      }
    })

    return () => {
      subscription.unsubscribe()
    }
  }, [fetchUserData])

  const signIn = useCallback(async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
  }, [])

  const signOut = useCallback(async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    setUser(null)
  }, [])

  const hasRole = useCallback(
    (role: UserRole): boolean => user?.roles.includes(role) ?? false,
    [user]
  )

  const hasAnyRole = useCallback(
    (roles: UserRole[]): boolean => roles.some((role) => user?.roles.includes(role)),
    [user]
  )

  const value = useMemo<AuthContextType>(
    () => ({ user, isLoading, signIn, signOut, hasRole, hasAnyRole }),
    [user, isLoading, signIn, signOut, hasRole, hasAnyRole]
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

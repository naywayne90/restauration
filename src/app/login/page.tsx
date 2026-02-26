"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Mail, Lock, Loader2, UtensilsCrossed } from "lucide-react";
import { createClient } from "@/utils/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader } from "@/components/ui/card";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError("Email ou mot de passe incorrect.");
      setIsLoading(false);
      return;
    }

    // Fetch user roles to determine redirect
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: roles } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", user.id);

      const userRoles = roles?.map((r) => r.role) || [];

      // Redirect based on role priority
      const roleRedirects: Record<string, string> = {
        superadmin: "/app/admin/dashboard",
        milys_admin: "/app/admin/dashboard",
        milys_kitchen: "/app/kitchen/production",
        milys_logistics: "/app/admin/deliveries",
        milys_cashier: "/app/cashier/scan",
        company_admin: "/app/admin/companies",
        company_cashier: "/app/cashier/scan",
        third_party_cashier: "/app/cashier/scan",
        employee: "/app/employee/dashboard",
      };

      const priority = [
        "superadmin", "milys_admin", "milys_kitchen", "milys_logistics",
        "milys_cashier", "company_admin", "company_cashier",
        "third_party_cashier", "employee",
      ];

      const redirectRole = priority.find((r) => userRoles.includes(r)) || "employee";
      router.push(roleRedirects[redirectRole]);
    } else {
      router.push("/app/employee/dashboard");
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-orange-50 to-orange-100 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="flex flex-col items-center space-y-4 pb-2">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-orange-500">
            <UtensilsCrossed className="h-8 w-8 text-white" />
          </div>
          <div className="text-center">
            <h1 className="text-2xl font-bold tracking-tight">MILY&apos;S</h1>
            <p className="text-sm text-muted-foreground">
              Connectez-vous à votre espace
            </p>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="rounded-md bg-red-50 p-3 text-center text-sm text-red-600">
                {error}
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  id="email"
                  type="email"
                  placeholder="votre@email.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="pl-10"
                  required
                  disabled={isLoading}
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Mot de passe</Label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  id="password"
                  type="password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pl-10"
                  required
                  disabled={isLoading}
                />
              </div>
            </div>

            <Button
              type="submit"
              className="w-full bg-orange-500 hover:bg-orange-600"
              disabled={isLoading}
            >
              {isLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Connexion en cours...
                </>
              ) : (
                "Se connecter"
              )}
            </Button>

            <div className="text-center">
              <a href="#" className="text-sm text-orange-500 hover:underline">
                Mot de passe oublié ?
              </a>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

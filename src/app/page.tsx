import { createClient } from "@/utils/supabase/server";

export default async function Home() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  return (
    <div className="grid grid-rows-[20px_1fr_20px] items-center justify-items-center min-h-screen p-8 pb-20 gap-16 sm:p-20">
      <main className="flex flex-col gap-8 row-start-2 items-center">
        <h1 className="text-4xl font-bold">Restauration</h1>
        <p className="text-lg text-gray-600">
          Application de restauration propulsée par Next.js et Supabase
        </p>

        <div className="flex flex-col items-center gap-4 mt-8 p-6 rounded-lg border border-gray-200">
          <h2 className="text-xl font-semibold">Statut de la connexion Supabase</h2>
          {user ? (
            <p className="text-green-600">
              Connecté en tant que : {user.email}
            </p>
          ) : (
            <p className="text-gray-500">
              Aucun utilisateur connecté — Supabase est configuré et prêt.
            </p>
          )}
        </div>
      </main>
    </div>
  );
}

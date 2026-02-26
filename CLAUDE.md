# MILY'S - Application de Restauration d'Entreprise

## Description du projet

MILY'S est une plateforme SaaS de gestion de restauration d'entreprise au Cameroun. Elle couvre l'ensemble de la chaîne : gestion des menus, commandes des employés, production en cuisine, livraison, facturation et paiements.

## Stack technique

- **Framework** : Next.js 16 (App Router, TypeScript)
- **UI** : Tailwind CSS 4 + shadcn/ui (composants Radix)
- **Backend** : Supabase (PostgreSQL, Auth, RLS, Realtime)
- **Icônes** : Lucide React
- **Déploiement** : Vercel (prévu)

## Structure du projet

```
src/
├── app/                        # Routes Next.js (App Router)
│   ├── login/                  # Page de connexion
│   ├── app/                    # Routes protégées
│   │   ├── admin/              # Back-office admin (AdminLayout)
│   │   │   ├── dashboard/
│   │   │   ├── companies/
│   │   │   ├── employees/
│   │   │   ├── dishes/
│   │   │   ├── menus/
│   │   │   ├── orders/
│   │   │   ├── invoices/
│   │   │   ├── deliveries/
│   │   │   ├── suppliers/
│   │   │   ├── stock/
│   │   │   └── settings/
│   │   ├── employee/           # Espace employé (EmployeeLayout)
│   │   │   ├── dashboard/
│   │   │   ├── menu/
│   │   │   ├── orders/
│   │   │   ├── qrcode/
│   │   │   └── profile/
│   │   ├── kitchen/            # Espace cuisine (AdminLayout)
│   │   │   ├── production/
│   │   │   └── stock/
│   │   └── cashier/            # Espace caissier (AdminLayout)
│   │       ├── scan/
│   │       └── report/
│   └── gourmet/                # Pages publiques (PublicLayout)
│       ├── entreprises/
│       ├── comment-ca-marche/
│       └── contact/
├── components/
│   ├── layouts/                # AdminLayout, EmployeeLayout, PublicLayout
│   ├── ui/                     # Composants shadcn/ui
│   └── placeholder-page.tsx    # Composant placeholder réutilisable
├── contexts/
│   └── auth-context.tsx        # AuthProvider avec Supabase Auth
├── hooks/
│   └── use-auth.ts             # Hook useAuth()
├── lib/
│   ├── types.ts                # Types TypeScript (UserRole, Profile, etc.)
│   ├── role-config.ts          # Configuration des rôles et redirections
│   └── utils.ts                # Utilitaire cn() pour classes CSS
├── utils/supabase/
│   ├── client.ts               # Client Supabase (navigateur)
│   ├── server.ts               # Client Supabase (serveur)
│   └── middleware.ts            # Utilitaire de session
└── middleware.ts                # Middleware Next.js (auth + session)

supabase/
└── schema.sql                  # Schéma complet (38 tables, RLS, seeds)
```

## Rôles utilisateurs

| Rôle | Description | Accès principal |
|------|------------|----------------|
| `superadmin` | Super administrateur | /app/admin/* |
| `milys_admin` | Admin MILY'S | /app/admin/* |
| `milys_kitchen` | Équipe cuisine | /app/kitchen/* |
| `milys_logistics` | Logistique | /app/admin/deliveries |
| `milys_cashier` | Caissier MILY'S | /app/cashier/* |
| `company_admin` | Admin entreprise cliente | /app/admin/companies |
| `company_cashier` | Caissier entreprise | /app/cashier/* |
| `third_party_cashier` | Caissier tiers | /app/cashier/* |
| `employee` | Employé | /app/employee/* |

## Design System

- **Couleur primaire** : Orange `#F97316`
- **Couleur succès** : Vert `#16A34A`
- **Sidebar** : Slate foncé `#0F172A`
- **Police** : Inter (sans-serif)
- **Composants** : shadcn/ui (button, input, card, dialog, table, tabs, badge, toast, skeleton, avatar, sheet, select, dropdown-menu, separator, label)

## Commandes utiles

```bash
npm run dev       # Serveur de développement
npm run build     # Build de production
npm run start     # Serveur de production
npm run lint      # Linter ESLint
```

## Variables d'environnement

Copier `.env.example` en `.env.local` et remplir :

```
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

## Conventions

- **Langue** : Interface en français
- **Monnaie** : FCFA (Franc CFA)
- **Fichiers** : kebab-case pour les fichiers, PascalCase pour les composants
- **Routes** : kebab-case (ex: `/gourmet/comment-ca-marche`)
- **Auth** : Toutes les routes `/app/*` sont protégées par middleware
- **RLS** : Toutes les tables Supabase ont Row Level Security activé

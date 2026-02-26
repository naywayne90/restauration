# MILY'S Gourmet - Application de Restauration d'Entreprise

## Description du projet

MILY'S Gourmet est une plateforme SaaS de gestion de restauration d'entreprise en Côte d'Ivoire (Abidjan). Elle couvre l'ensemble de la chaîne : gestion des menus, commandes des employés, production en cuisine, livraison, facturation et paiements.

## Stack technique

- **Framework** : Vite + React 19 (SPA, TypeScript)
- **Routing** : React Router v7
- **UI** : Tailwind CSS 3 + shadcn/ui (composants Radix)
- **Forms** : React Hook Form + Zod
- **State** : TanStack React Query
- **Backend** : Supabase (PostgreSQL, Auth, RLS, Realtime)
- **Icônes** : Lucide React
- **PWA** : vite-plugin-pwa
- **Déploiement** : Vercel (prévu)

## Structure du projet

```
src/
├── App.tsx                         # Routes React Router + ProtectedRoute
├── main.tsx                        # Entry point (BrowserRouter, QueryClient, AuthProvider)
├── components/
│   ├── layout/                     # Layouts
│   │   ├── AdminLayout.tsx         # Admin/Kitchen/Cashier layout (sidebar + Sheet mobile)
│   │   ├── EmployeeLayout.tsx      # Employee layout (sidebar + bottom nav mobile)
│   │   ├── PublicLayout.tsx        # Public marketing layout (header + footer)
│   │   ├── Sidebar.tsx             # Collapsible sidebar (dark slate #0F172A)
│   │   ├── Header.tsx              # Header (breadcrumb, notifications, avatar dropdown)
│   │   └── MobileNav.tsx           # Bottom nav bar mobile (5 items max)
│   ├── shared/                     # Composants partagés
│   │   ├── ForbiddenPage.tsx       # Page 403
│   │   ├── ErrorBoundary.tsx       # Error boundary
│   │   ├── LoadingSpinner.tsx      # Loader / PageLoader
│   │   ├── EmptyState.tsx          # État vide
│   │   └── ConfirmDialog.tsx       # Dialog de confirmation
│   ├── ui/                         # Composants shadcn/ui
│   └── placeholder-page.tsx        # Composant placeholder réutilisable
├── contexts/
│   └── auth-context.tsx            # AuthProvider (Supabase Auth + profil + rôles)
├── hooks/
│   └── use-auth.ts                 # Hook useAuth()
├── lib/
│   ├── types.ts                    # Types TypeScript (UserRole, Profile, Order, etc.)
│   ├── constants.ts                # Navigation, role configs, status labels
│   ├── role-config.ts              # ROLE_LABELS, ROLE_REDIRECT, getDefaultRedirect()
│   ├── supabase.ts                 # Client Supabase (navigateur)
│   └── utils.ts                    # cn(), formatCurrency(), formatDate(), getInitials()
├── pages/
│   ├── admin/                      # Pages administration
│   │   ├── Dashboard.tsx           # KPIs, commandes récentes, liens rapides
│   │   ├── Companies.tsx           # CRUD entreprises
│   │   ├── Employees.tsx           # CRUD employés
│   │   ├── Dishes.tsx              # Catalogue plats
│   │   ├── Menus.tsx               # Menus hebdomadaires
│   │   ├── Orders.tsx              # Suivi commandes
│   │   ├── Invoices.tsx            # Facturation
│   │   ├── Deliveries.tsx          # Livraisons
│   │   ├── Suppliers.tsx           # Fournisseurs (placeholder)
│   │   ├── Stock.tsx               # Gestion stock (placeholder)
│   │   └── Settings.tsx            # Paramètres plateforme
│   ├── employee/                   # Pages employé
│   │   ├── Dashboard.tsx           # Menu du jour, stats dépenses
│   │   ├── WeeklyMenu.tsx          # Grille menu 5 jours
│   │   ├── MyOrders.tsx            # Historique commandes
│   │   ├── MyQRCode.tsx            # QR code employé
│   │   └── Profile.tsx             # Profil personnel
│   ├── kitchen/                    # Pages cuisine
│   │   ├── DailyProduction.tsx     # Production du jour
│   │   └── StockAlerts.tsx         # Alertes stock
│   ├── cashier/                    # Pages caissier
│   │   ├── ScanQR.tsx              # Scanner QR
│   │   └── DailyReport.tsx         # Rapport journalier
│   ├── public/                     # Pages marketing
│   │   ├── LandingPage.tsx         # Page d'accueil
│   │   ├── ForCompanies.tsx        # Offres entreprises
│   │   ├── HowItWorks.tsx          # Comment ça marche
│   │   └── Contact.tsx             # Contact + formulaire
│   └── auth/                       # Authentification
│       ├── LoginPage.tsx           # Connexion (split-screen, food illustration)
│       └── ForgotPasswordPage.tsx  # Réinitialisation mot de passe
└── styles/
    └── globals.css                 # Variables CSS, Tailwind layers

supabase/
└── schema.sql                      # Schéma complet (38 tables, RLS, triggers, seeds)
```

## Routes

```
/login                              → LoginPage
/forgot-password                    → ForgotPasswordPage
/app/admin/dashboard                → Admin Dashboard
/app/admin/companies                → Entreprises CRUD
/app/admin/employees                → Employés CRUD
/app/admin/dishes                   → Plats CRUD
/app/admin/menus                    → Gestion menus
/app/admin/orders                   → Gestion commandes
/app/admin/invoices                 → Factures
/app/admin/deliveries               → Livraisons
/app/admin/suppliers                → Fournisseurs CRUD
/app/admin/stock                    → Gestion stock
/app/admin/settings                 → Paramètres
/app/kitchen/production             → Production du jour
/app/kitchen/stock                  → Alertes stock
/app/cashier/scan                   → Scanner QR
/app/cashier/report                 → Rapport journalier
/app/employee/dashboard             → Dashboard employé
/app/employee/menu                  → Menu hebdomadaire
/app/employee/orders                → Mes commandes
/app/employee/qrcode                → Mon QR Code
/app/employee/profile               → Mon profil
/gourmet                            → Landing Page (public)
/gourmet/entreprises                → Pour les entreprises (public)
/gourmet/comment-ca-marche          → Comment ça marche (public)
/gourmet/contact                    → Contact (public)
```

## Rôles utilisateurs & permissions

| Rôle | Description | Routes autorisées |
|------|------------|-------------------|
| `superadmin` | Super administrateur | Toutes les routes /app/* |
| `milys_admin` | Admin MILY'S | Toutes les routes /app/* |
| `milys_kitchen` | Équipe cuisine | /app/kitchen/* |
| `milys_logistics` | Logistique | /app/admin/* (limité deliveries) |
| `milys_cashier` | Caissier MILY'S | /app/cashier/* |
| `company_admin` | Admin entreprise cliente | /app/admin/* (sa company) |
| `company_cashier` | Caissier entreprise | /app/cashier/* |
| `third_party_cashier` | Caissier tiers | /app/cashier/* |
| `employee` | Employé | /app/employee/* |

## Comptes de test

| Email | Mot de passe | Rôle | Entreprise |
|-------|-------------|------|-----------|
| admin@milys.ci | MilysAdmin2026! | superadmin | MILY'S |
| kitchen@milys.ci | MilysAdmin2026! | milys_kitchen | MILY'S |
| cashier@milys.ci | MilysAdmin2026! | milys_cashier | MILY'S |
| rh@orange.ci | MilysAdmin2026! | company_admin | Orange CI |
| employe1@orange.ci | MilysAdmin2026! | employee | Orange CI |

## Design System

- **Couleur primaire** : Orange `#F97316`
- **Couleur succès** : Vert `#16A34A`
- **Sidebar** : Slate foncé `#0F172A`
- **Public background** : `#FAFAF9`
- **Police** : Inter (sans-serif)
- **Composants** : shadcn/ui (button, input, card, dialog, table, tabs, badge, toast, skeleton, avatar, sheet, select, dropdown-menu, separator, label, alert, form, scroll-area, switch, checkbox, calendar, popover, progress, tooltip, command, textarea)

## Commandes utiles

```bash
npm run dev       # Serveur de développement (Vite)
npm run build     # Build de production (tsc + vite build)
npm run preview   # Preview du build de production
npm run lint      # Linter ESLint
```

## Variables d'environnement

Copier `.env.example` en `.env.local` et remplir :

```
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
```

## Base de données (Supabase)

### Tables principales (38)

- **Entreprises** : companies, company_sites, company_contracts
- **Utilisateurs** : profiles (PK = auth.users.id), user_roles
- **Catalogue** : dishes, dish_allergens, dish_ratings, ingredients, dish_ingredients
- **Fournisseurs** : suppliers, supplier_ingredients, purchase_orders, purchase_order_items
- **Stock** : stock_movements (trigger auto-update ingredients.current_stock)
- **Menus** : menus, menu_items, weekly_plans, weekly_plan_items
- **Commandes** : orders (trigger auto QR + calcul parts), qr_codes, qr_scans
- **Tickets** : physical_tickets
- **Production** : production_batches, formulas
- **Livraisons** : drivers, deliveries, delivery_items
- **Facturation** : invoices, invoice_items, invoice_employee_details, payments, invoice_payments
- **Système** : notifications, audit_logs, app_config

### Triggers

- `set_updated_at()` : auto-update updated_at sur 11 tables
- `audit_trigger_fn()` : log INSERT/UPDATE/DELETE sur orders, invoices, payments, deliveries
- `compute_order_shares()` : calcul automatique company_share/employee_share
- `generate_qr_on_order()` : génération QR code à la création d'une commande
- `update_ingredient_stock()` : mise à jour stock après mouvement

### RLS

Toutes les 38 tables ont Row Level Security activé avec policies adaptées aux rôles.

### Seeds

- 3 entreprises (Orange CI, TotalEnergies CI, SGBCI)
- 6 sites (2 par entreprise)
- 3 contrats
- 15 plats ivoiriens et internationaux
- 15 ingrédients
- 3 fournisseurs
- 4 formules (Standard, Premium, Végétarien, Économique)
- 1 menu hebdomadaire
- 23 profils employés avec rôles
- 15 configurations applicatives

## Conventions

- **Langue** : Interface en français
- **Monnaie** : FCFA (Franc CFA / XOF)
- **Fichiers composants** : PascalCase (ex: `AdminLayout.tsx`)
- **Fichiers lib** : kebab-case (ex: `role-config.ts`)
- **Hooks** : useCamelCase (ex: `useAuth`)
- **Routes** : kebab-case (ex: `/gourmet/comment-ca-marche`)
- **Base de données** : snake_case (ex: `company_sites`)
- **Auth** : Toutes les routes `/app/*` sont protégées par ProtectedRoute avec vérification de rôle
- **RLS** : Toutes les tables Supabase ont Row Level Security activé
- **Profiles** : La table profiles a `id UUID PRIMARY KEY REFERENCES auth.users(id)` — pas de colonne `user_id` séparée

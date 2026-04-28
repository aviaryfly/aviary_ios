# Demo mode foundation + avatar upload — Design

**Date:** 2026-04-28
**Phase:** 1 of 6 (foundation for the demo-mode rollout)
**Status:** approved

## Goal

Replace the hardcoded "demo-flavored" data scattered across the app with a backend-driven, role-aware demo dataset gated by a per-user toggle. Phase 1 delivers the toggle infrastructure and one fully-wired vertical (avatars) so subsequent phases can reuse the pattern mechanically.

When the toggle is **OFF**, the app shows the signed-in user's real profile (avatar, name, role). When **ON**, it transparently swaps in canonical demo data fetched from Supabase.

## Out of scope (deferred to later phases)

This spec covers Phase 1 only. The following are deliberately *not* part of this work:

- Phase 2: pilot certifications, equipment, insurance, payouts, performance metrics; customer payment methods, addresses, notification prefs.
- Phase 3: gigs, business profiles, gig deliverables, job posts, map-pin queries.
- Phase 4: earnings, weekly bars, recent gigs feed, customer aggregate stats.
- Phase 5: messages, conversations, ratings.
- Phase 6: pre-flight checklist, deliverable uploads, in-flight telemetry.

Hardcoded demo data outside the avatar/profile-name surface stays as-is until its phase lands. Each later phase introduces its own `demo_*` table seeded with the strings/numbers presently hardcoded in the relevant view.

## User stories

- As a pilot user, I can tap my profile avatar and upload a real photo from my photo library; it persists across sessions and devices.
- As any user, I can open Profile → Settings and flip a "Demo mode" toggle.
- When the toggle is ON, my avatar, displayed name, and role-derived UI render the canonical demo data for my current role; flipping it OFF returns the view to my real data.
- The toggle does not change which Supabase row the app writes to. Avatar upload is disabled while demo mode is on.

## Architecture

### New Swift components

| File | Type | Responsibility |
|---|---|---|
| `Aviary/Settings/DemoModeStore.swift` | `@MainActor final class DemoModeStore: ObservableObject` | Single `@Published var isOn: Bool` backed by `UserDefaults` key `"demoMode.isOn"`. Default `false`. Injected as `@EnvironmentObject`. |
| `Aviary/Settings/SettingsScreen.swift` | SwiftUI `View` | Hosts the demo-mode toggle. Designed to grow with future settings. |
| `Aviary/Backend/DemoProfileService.swift` | `actor` or `@MainActor final class` | `func demoProfile(for role: UserRole) async throws -> UserProfile`. Caches the result for the lifetime of the process. |
| `Aviary/Backend/AvatarService.swift` | `enum` with static methods | `upload(data:contentType:userID:) async throws -> URL` and `setProfileAvatar(_ url: URL, for userID: UUID) async throws`. |

### Modified Swift components

| File | Change |
|---|---|
| `Aviary/Models/UserProfile.swift` | Add `let avatarUrl: String?` with `CodingKeys` mapping to `avatar_url`. |
| `Aviary/Auth/AuthViewModel.swift` | Add `@Published private(set) var displayedProfile: UserProfile?` — derived from `(realProfile, demoModeStore.isOn, cachedDemoProfile)`. Subscribe to `DemoModeStore.$isOn` and to its own real-profile updates; on demo flip, fetch via `DemoProfileService` if not cached. Existing `state` enum remains the source of auth state; `displayedProfile` is the read path for UI. |
| `Aviary/AviaryApp.swift` | Construct one `DemoModeStore`, inject as `@StateObject` + `.environmentObject(...)`. Pass into `AuthViewModel`'s init so the VM can observe it. |
| `Aviary/ContentView.swift` | `RootView` reads `auth.displayedProfile` (falling back to the signed-in profile while demo data loads) and passes it down to `PilotRootView` / `CustomerRootView`. Existing prop signatures unchanged. |
| `Aviary/AccountScreens.swift` | `ProfileScreen`: replace static `Avatar(...)` header with a `ProfileAvatarView` that renders `avatarUrl` if present, falls back to initials, and is tappable when demo mode is OFF (opens `PhotosPicker`). Add a "Settings" row between Messages and Sign out that pushes/sheets `SettingsScreen`. |
| (new) `Aviary/Components.swift` or co-located | Add `ProfileAvatarView` if it doesn't already exist as a reusable component. |

### Data flow — demo toggle

```
User taps toggle in SettingsScreen
  → DemoModeStore.isOn = true
  → UserDefaults persists
  → AuthViewModel observes change
     → if cachedDemoProfile == nil: DemoProfileService.demoProfile(for: realProfile.role)
     → set displayedProfile = demoProfile (with role overridden to match real role for safety)
  → SwiftUI re-renders ProfileScreen, HomeScreen header, etc. with new avatar/name
```

When toggled OFF: `displayedProfile = realProfile`. No network call needed.

### Data flow — avatar upload

```
User taps avatar (demo OFF) in ProfileScreen
  → PhotosPicker presents
  → On selection: load Data
  → AvatarService.upload(data:contentType:userID:)
     → Supabase Storage PUT /avatars/users/{user_id}/avatar.{ext}
     → returns public URL
  → AvatarService.setProfileAvatar(url, for: userID)
     → UPDATE profiles SET avatar_url = url WHERE id = userID
  → AuthViewModel.refresh() → re-fetches profile → displayedProfile updates
```

While demo mode is ON the avatar is rendered non-tappable: the underlying `Button` is replaced with a plain view (no press feedback, no `PhotosPicker` trigger), and the avatar's container takes a 0.85 opacity to subtly signal it's locked. No inline error string — the toggle in Settings is the one canonical place that explains demo mode.

## Schema

### Migration: `add_avatar_url_to_profiles`

```sql
alter table public.profiles
  add column avatar_url text;
```

### Migration: `create_demo_profiles`

```sql
create table public.demo_profiles (
  id          uuid primary key default gen_random_uuid(),
  role        public.user_role not null unique,
  email       text not null,
  first_name  text,
  last_name   text,
  avatar_url  text,
  created_at  timestamptz not null default now()
);

alter table public.demo_profiles enable row level security;

create policy "demo_profiles readable by authenticated"
  on public.demo_profiles
  for select
  to authenticated
  using (true);

-- No insert/update/delete policy: demo rows are managed via service role only.
```

`role` is `unique`, so there is exactly one demo profile per role. The Swift fetch is a single `eq("role", value: role.rawValue).single()`.

### Seed: `seed_demo_profiles`

```sql
insert into public.demo_profiles (role, email, first_name, last_name, avatar_url)
values
  ('pilot',    'demo+pilot@aviary.app',    'Casey', 'Park',   '<pilot-demo-url>'),
  ('customer', 'demo+customer@aviary.app', 'Marin', 'Realty', '<customer-demo-url>');
```

The two avatar URLs point at images in the `avatars` bucket under `demo/pilot.jpg` and `demo/customer.jpg`. The seed migration runs after the storage bucket is created.

## Storage

### Bucket: `avatars`

- **Public read.** Avatars are non-sensitive and we want plain `<img src>` semantics in the long run.
- **Path layout:**
  - `users/{user_id}/avatar.{ext}` — written by the user via app upload.
  - `demo/{role}.{ext}` — seeded once. Two files: `demo/pilot.jpg`, `demo/customer.jpg`.
- **RLS policies (storage.objects):**
  - `select` allowed for everyone (public read).
  - `insert` / `update` / `delete` allowed only when `bucket_id = 'avatars' AND (storage.foldername(name))[1] = 'users' AND (storage.foldername(name))[2] = auth.uid()::text`.
  - Demo subfolder writes blocked from app-side; managed via service role.

A single old avatar per user is overwritten on re-upload (path is deterministic except for extension; service rewrites with the new extension and DELETEs any prior `users/{user_id}/avatar.*` siblings to avoid orphans).

## RLS on `profiles`

`profiles` already has RLS enabled and existing policies for select/update of the user's own row. The new `avatar_url` column is covered by those policies — no policy changes needed.

## Error and edge cases

- **Demo profile fetch fails.** The `displayedProfile` falls back to `realProfile` and `errorMessage` surfaces a non-fatal "Couldn't load demo data, showing your account." message in `SettingsScreen`. The toggle stays ON so the user can retry by toggling off/on.
- **Avatar upload fails mid-flight.** The user's existing `avatar_url` is unchanged. A toast/inline error is shown in `ProfileScreen`. No partial writes.
- **User has no avatar yet.** `ProfileAvatarView` falls back to the existing initials rendering (already used by `Avatar(...)` in `Components.swift`).
- **Toggle flipped before first demo fetch returns.** UI immediately reflects intent; the `displayedProfile` becomes the demo one once the fetch resolves. Briefly stale state is acceptable (sub-second).
- **User signs out.** `DemoModeStore.isOn` persists per-device per the design (UserDefaults). The next sign-in starts with the toggle in whatever state the user left it.

## Testing

- Unit test `DemoModeStore` persistence (set → init new instance → expect persisted value).
- Unit test `AuthViewModel.displayedProfile` derivation across the four `(real, demoOn, demoCached)` permutations using a fake `DemoProfileService`.
- Manual UAT against the live Supabase project:
  - Sign up as a fresh pilot → avatar shows initials → upload photo → reload app → photo persists.
  - Toggle demo on → avatar + name swap to "Casey Park" with seeded photo.
  - Toggle demo off → reverts.
  - Sign in as a customer (separate account) → toggle on → "Marin Realty" demo profile appears.

## Open questions / non-decisions

None blocking. The choice of demo seed names ("Casey Park", "Marin Realty") and the two demo avatar images can be set at implementation time.

## Files touched (summary)

**Create:**
- `Aviary/Settings/DemoModeStore.swift`
- `Aviary/Settings/SettingsScreen.swift`
- `Aviary/Backend/DemoProfileService.swift`
- `Aviary/Backend/AvatarService.swift`
- Migration SQL via Supabase MCP: `add_avatar_url_to_profiles`, `create_demo_profiles`, `seed_demo_profiles`
- Storage bucket `avatars` + 2 demo image uploads

**Modify:**
- `Aviary/Models/UserProfile.swift`
- `Aviary/Auth/AuthViewModel.swift`
- `Aviary/AviaryApp.swift`
- `Aviary/ContentView.swift`
- `Aviary/AccountScreens.swift`
- `Aviary/Components.swift` (only if `ProfileAvatarView` is added there)

**Unchanged but worth noting:** `HomeScreen.swift`, `CustomerHomeScreen.swift`, etc. consume `profile:` already; they get the demo swap "for free" because `RootView` passes the effective profile down.

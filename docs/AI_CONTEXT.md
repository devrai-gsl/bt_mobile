# Browntape Mobile — AI Context

Use this document as shared context when working with AI assistants on the Browntape mobile app and its CakePHP backend.

## What We're Building

A **native Flutter mobile app** (`bt_mobile`) for **Browntape** — a multi-tenant e-commerce / warehouse operations platform by Ginesys. The backend is **CakePHP 2.10.24** on **PHP 7.4** (`bt-app`). The app targets warehouse staff: order fulfillment, returns QC, picklists, etc.

**Repos / paths:**

| Project | Path |
|---------|------|
| Mobile (Flutter) | `/var/www/bt_mobile` |
| Backend (CakePHP) | `/var/www/bt-app` |

---

## Tech Stack

| Layer | Stack |
|-------|-------|
| Mobile | Flutter (Dart `^3.12`, Material 3), no routing/state-mgmt packages yet |
| Backend | CakePHP 2.10 MVC, Redis, multi-tenant MySQL per company |
| Auth (new mobile) | Ginesys SSO → opaque Redis tokens via `X-Mobile-Token` |
| Auth (legacy mobile) | Vue 3 SPA at `/mobile` using CakePHP session cookies |
| Auth (integrations) | `X-username` + `X-auth-string` on versioned REST APIs |

---

## Mobile App Architecture

**Entry:** `lib/main.dart` → `lib/app.dart` (`BrowntapeApp`)

**State:** `ChangeNotifier` only (`AuthController`) — no Riverpod, Bloc, or go_router.

### Auth route switch (`lib/app.dart`)

| Route | Screen |
|-------|--------|
| `loading` | Spinner |
| `login` | `LoginScreen` |
| `continueAs` | `ContinueAsScreen` (remember-me) |
| `accessDenied` | `AccessDeniedScreen` (inventory managers blocked) |
| `dashboard` | `DashboardScreen` |

### Post-login shell

Bottom navigation only — **no sidebar/drawer**.

- `lib/widgets/navigation/bt_app_shell.dart`
- Tabs: Home, Orders, Returns, More (`AppNavId` enum)
- Only **Home** is implemented; other tabs show “coming soon” snackbars

### Key directories

```
lib/
├── config/app_config.dart          # API URL, dev flags
├── core/
│   ├── api/bt_api_client.dart      # HTTP + envelope parsing
│   ├── auth/                       # controller, repository, user profile
│   ├── storage/secure_session_store.dart
│   └── theme/bt_colors.dart
├── features/
│   ├── auth/                       # login, continue-as, access-denied
│   └── home/dashboard_screen.dart  # dashboard UI (mock data)
└── widgets/navigation/             # shell + bottom nav
```

---

## Mobile Config & Run Commands

Defined in `lib/config/app_config.dart`:

| Flag | Default | Purpose |
|------|---------|---------|
| `BT_API_BASE_URL` | `http://10.0.2.2` | Android emulator → host machine |
| `BT_SKIP_LOGIN` | `true` in debug, `false` in release | Mock session, no API |
| `BT_DEV_SANDBOX` | `false` | Tutorial Home widget for hot-reload practice |

```bash
flutter run --dart-define=BT_API_BASE_URL=http://10.0.2.2
flutter run --dart-define=BT_SKIP_LOGIN=false   # real login
flutter run --dart-define=BT_DEV_SANDBOX=true   # sandbox UI
```

**API base for auth:** `{BT_API_BASE_URL}/api/2.0/mobile_auth`

---

## Mobile Auth Flow (Implemented)

**Client files:** `auth_controller.dart`, `auth_repository.dart`, `bt_api_client.dart`, `secure_session_store.dart`

### Endpoints (only ones wired today)

| Endpoint | Method | Auth |
|----------|--------|------|
| `/api/2.0/mobile_auth/login.json` | POST | `{ email, password }` |
| `/api/2.0/mobile_auth/refresh.json` | POST | `{ refresh_token }` |
| `/api/2.0/mobile_auth/session.json` | GET | `X-Mobile-Token` |
| `/api/2.0/mobile_auth/logout.json` | POST | `X-Mobile-Token` |

### Response envelope

```json
{ "status": 200, "data": { ... }, "message": "..." }
```

Errors may include `data.expired: true` for token expiry.

**Token storage:** `flutter_secure_storage` (tokens + remembered profile); `shared_preferences` (remember-me flag).

**Dev skip login:** mock user in `dev_mock_session.dart` — Warehouse Manager, role 23, warehouse "Goa Warehouse", `access_level: warehouse_scoped`.

---

## User Access Levels (Mobile)

From backend `MobileAuthService` → consumed in `UserProfile`:

| `role_id` | `access_level` | Mobile behavior |
|-----------|----------------|-----------------|
| 19 | `inventory_denied` | Blocked → Access Denied screen |
| 23 | `warehouse_scoped` | Warehouse manager; location pill shows warehouse |
| 15, 20, 22 | `full` | All locations; location switcher (placeholder) |
| other | `denied` | Not allowed |

**User profile fields:** `id`, `email`, `username`, `first_name`, `last_name`, `role_id`, `role_title`, `company_id`, `company_title`, `warehouse_id`, `warehouse_name`, `access_level`, `can_persist_session`

---

## Dashboard UI (Current State)

**File:** `lib/features/home/dashboard_screen.dart`

Implemented as **static/mock UI** matching design mockups:

- Header: Browntape logo + notification bell (badge "3")
- Greeting: "Hi {firstName}" + location pill
- Orders Overview grid: New (25), Packing (9), Ready to ship (18), SLA Breach (2)
- Return Actions: Acknowledge Returns, Perform QC (3 Pending)
- More: Create Return, Scan Picklist
- Bottom nav: Home / Orders / Returns / More

All actions except auth use `_comingSoon()` snackbar stubs — **no real order/return API calls yet**.

**Branding:** green `#3D9A4E`, tokens in `lib/core/theme/bt_colors.dart`, logo at `assets/images/browntape_logo.png`.

---

## Backend Architecture (CakePHP 2.10)

**Structure:**

- Controllers: `app/Controller/`
- Models: `app/Model/` (Order.php, User.php, Warehouse.php, etc.)
- Mobile services: `app/Lib/Mobile/` (`MobileAuthService.php`, `MobileSsoClient.php`)
- API vendor layer: `app/Vendor/api/` (versions 0.1, 0.11, 0.12)
- Legacy mobile SPA: `app/vite-project/` served at `/mobile/*`

**Routing** (`app/Config/routes.php`):

- v0.x: `/{version}/{controller}/{action}.json` (e.g. `/0.12/returns/create.json`)
- v2.0+: `/api/{version}/{controller}/{action}.json` (e.g. `/api/2.0/mobile_auth/login.json`)
- Legacy mobile: `/mobile/*` → Vue SPA shell

**Multi-tenant:** per-company DB; tenant switch in `AppController`.

---

## Backend Mobile Auth (Implemented for Flutter)

**Files:**

- `app/Controller/MobileAuthController.php`
- `app/Lib/Mobile/MobileAuthService.php`
- `app/Lib/Mobile/MobileSsoClient.php`

**Flow:**

1. Login via Ginesys SSO (`/auth/go-apps/credentials/login` or token login)
2. Map SSO user → BT user via `User::ssoLogin()`
3. LOCAL env fallback: local password check
4. Issue 64-char hex `access_token` + `refresh_token` stored in Redis:
   - `mobile_session:{token}` — TTL 30 days
   - `mobile_refresh:{token}` — TTL 90 days
5. Client sends `X-Mobile-Token` header (or `mobile_token` query param)

**Important gap:** `X-Mobile-Token` is only validated in `MobileAuthController` today. It is **not yet wired** into `AppController` API auth for orders/returns endpoints.

---

## Legacy Mobile (Vue SPA) — Reference for New Flutter Features

The existing mobile web app at `/mobile` uses **session cookies**, not `X-Mobile-Token`. Its returns/QC endpoints are the best reference for what Flutter will eventually need.

### Returns (session auth, unversioned)

| Endpoint | Purpose |
|----------|---------|
| `POST /Returns/getItors` | Returns list for QC |
| `POST /Returns/getItorsCount` | Count for pagination |
| `POST /Returns/saveOrderReceiveReturns/` | Save QC |
| `POST /Returns/acknowledgeCourier/` | Courier ack |
| `GET /Returns/getAcknowledgedReturns` | Acknowledged list |
| `POST /Returns/createReturnOrder` | Create return |
| `POST /Returns/qc_media_presign_put` | Azure media presign |
| `POST /Returns/qc_media_register` | Register QC media |

More endpoints live in `app/vite-project/src/service/`.

### Versioned REST (header auth for integrations)

- `/{version}/returns/create|get|receive|update.json`
- `/{version}/orders/index.json`, `create_order_return.json`
- `/{version}/warehouses/channelWarehouses.json`

Auth: `X-username` + `X-auth-string` where `auth_string = SHA1(api_secret + password_hash)`.

---

## What's Done vs. What's Next

| Area | Status |
|------|--------|
| Mobile auth (login, refresh, session, logout) | Done (Flutter + backend) |
| Remember-me / continue-as | Done |
| Access denied for inventory managers | Done |
| Dashboard UI shell | Done (mock data) |
| Bottom navigation | Done (Home only) |
| Orders API for mobile | Not started |
| Returns/QC API for mobile | Not started (legacy Vue has it) |
| Wire `X-Mobile-Token` into order/return endpoints | Not started |
| Location switcher | Placeholder |
| Scan picklist / QR | Placeholder |
| Push notifications | Not started |
| Tests | Not started |

---

## Conventions for New Work

### Flutter

- Extend `BtApiClient` or add domain-specific clients; reuse `{ status, data, message }` envelope parsing
- Pass `X-Mobile-Token` from `AuthController.session.accessToken`
- Use `BtColors` for dashboard-style UI
- New bottom-nav tabs: add `AppNavId` case + screen in `bt_app_shell.dart`
- Feature stubs: follow `_comingSoon(context, 'Feature')` pattern in `dashboard_screen.dart`
- Keep changes minimal; match existing file structure and naming
- **No sidebar** — use bottom nav only

### Backend (when adding mobile APIs)

- Prefer `/api/2.0/{controller}/{action}.json` pattern
- Add controllers under `app/Controller/` or extend existing ones
- Validate `X-Mobile-Token` via `MobileAuthService` (may need middleware in `AppController`)
- Respect `access_level` and `warehouse_id` scoping for role 23
- Return JSON via existing `AppController::json()` envelope

---

## Dependencies (Flutter)

```yaml
http: ^1.2.2
flutter_secure_storage: ^9.2.4
shared_preferences: ^2.3.3
url_launcher: ^6.3.1   # SSO portal link on login screen
```

No routing package, no code generation, no state management beyond `ChangeNotifier`.

---

## Example AI Prompt Prefix

> I'm building a Flutter mobile app (`/var/www/bt_mobile`) for Browntape warehouse operations. Backend is CakePHP 2.10 (`/var/www/bt-app`). Auth is done via `/api/2.0/mobile_auth/*` with `X-Mobile-Token`. Dashboard UI exists with mock data; bottom nav has Home/Orders/Returns/More. Legacy mobile web at `/mobile` uses session-based `/Returns/*` endpoints — new Flutter features should eventually get v2 mobile APIs with token auth. Follow existing patterns in `BtApiClient`, `AuthController`, `BtAppShell`, and `BtColors`. Minimize scope; no sidebar — use bottom nav only.

---


## Jira Epic: BTA-16468 — Browntape Mobile App

**Source:** [https://ginesysone.atlassian.net/browse/BTA-16468](https://ginesysone.atlassian.net/browse/BTA-16468)  
**Status:** Open · **Type:** Epic · **Priority:** Medium  
**Reporter:** Lorraine Pinto · **Developer:** Devrai Revadkar  
**Created:** 2026-04-28 · **Updated:** 2026-06-10

The epic has no description body in Jira. Scope is defined by the linked stories below.

### Story index

| Key | Summary | Status |
|-----|---------|--------|
| [BTA-16469](#bta-16469) | BT App: Implement Authentication, Session Management, and Role-Based Access Control | Open |
| [BTA-16470](#bta-16470) | BT App: Implement Single-Session Enforcement and Session Conflict Flow | Open |
| [BTA-16479](#bta-16479) | BT App: Dashboard | Open |
| [BTA-16462](#bta-16462) | BT App: Location Switcher for Full-Access Roles | Open |
| [BTA-16481](#bta-16481) | BT App: Build Order List  | Open |
| [BTA-16480](#bta-16480) | BT App: Build Order Processing Screen | Open |
| [BTA-16486](#bta-16486) | BT App: Return Module -Acknowledgement, QC, Create and View Returns | Open |
| [BTA-16463](#bta-16463) | BT App: Scan Picklist | Open |
| [BTA-16490](#bta-16490) | BT App: Notification and Notificaiton Setting | Open |
| [BTA-16464](#bta-16464) | BT App: Non-Functional Requirements | Open |

> **Implementation note:** Jira stories reference a **side navigation drawer**. The current Flutter codebase uses **bottom navigation** (no drawer). Treat drawer references as bottom-nav / More-tab equivalents unless product reverts to drawer.


### BTA-16469: BT App: Implement Authentication, Session Management, and Role-Based Access Control

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16469

Objective
Deliver a login screen, secure session management, and role-based routing so every user lands in the correct app state after authentication — including the Inventory Manager access-denied state and Warehouse Manager data scoping.
Proposed Solution
Login Screen
Two input fields: Email and Password
"Remember Me" toggle below the fields, defaulting to ON
Primary CTA: "Login" button
Supporting note below the CTA: 
"Your Browntape credentials are managed via the Ginesys SSO portal. To reset your password or update your account, visit the SSO portal."
 — "SSO portal" is a tappable link opening https://sso.ginesys.one/login in the device's default browser
No forgot password flow, no social login, no biometric on the login screen
Field-Level Validation
Scenario
Error shown
Empty email on submit
"Email is required"
Empty password on submit
"Password is required"
Both empty
Both errors shown simultaneously
Invalid credentials
"Invalid email or password"
Session Persistence
Session token stored in OS-level secure storage (Keychain on iOS, Keystore on Android)
Token refresh handled silently in the background
Users remain logged in until explicit logout; closing, backgrounding, or device restart does not log the user out
When the session becomes invalid, the user is redirected to the Login screen
Remember Me ON: app opens directly to the Continue As screen
Remember Me OFF: session cleared on app logout; full credentials required on next open
Remember Me state stored per device
Only one remembered account per device at a time — a new login with Remember Me ON overwrites the previously saved session
Continue As Screen
On app open with a valid session or remembered account, the app displays the Continue As screen instead of the Login screen
Account card displays: user avatar (initials), full name, role, and company
For Warehouse Manager: company line also shows assigned warehouse as 
[Company] · [Warehouse]
Tapping "Continue" resumes the session and routes the user to the Dashboard
Tapping "Log in with a different account" navigates to the Login screen without clearing the saved session; the saved session is only overwritten when a new login with Remember Me ON is completed
If the saved session has been admin-revoked, tapping Continue redirects the user to the Login screen with a session-expired message
When an Inventory Manager logs in, their session is not saved regardless of the Remember Me state; on next app open they are always routed to the Login screen
Logout
Log Out option in the navigation drawer footer
Confirmation dialog shown before session is cleared
On confirm → session cleared → user returned to Login screen
Back button on Login screen → exits the app
Role-Based Access
Role
Access
Operations
Full access to all modules, all locations
Account Owner
Full access to all modules, all locations
Fulfillment Manager
Full access to all modules, all locations
Warehouse Manager
Full access to all modules — scoped to assigned warehouse only (API-level enforcement)
Inventory Manager
No app access — Access Denied screen shown on login
Inventory Manager Login Screen 
Full-screen informational state shown immediately after login for Inventory Manager role
Message displayed: _"Inventory not available on the mobile app. To manage inventory operations, please open Browntape using your desktop browser.”
No navigation drawer, no modules, no data loaded
Single action: Log Out button → returns to Login screen
Remember Me is ignored for Inventory Manager — account persistence is disabled regardless of toggle state
Full Access Roles — Location Indicator
Full-access roles see an 
interactive location indicator
 in the Dashboard header showing their currently active location
Tapping the location indicator opens the Location Switcher
Location switching is only available from the Dashboard; it is not accessible from Orders List, Returns, or any other screen
All data (orders, returns, metrics) reflects the currently selected location
The last selected location is saved to the user's account and persists across sessions and devices
Warehouse Manager — Data Scoping
Dashboard counts, Orders list, Returns list, and all data-driven screens reflect assigned warehouse only
The location indicator in the Dashboard header is 
non-interactive
 for Warehouse Manager — it displays the assigned warehouse name only and is not tappable. The non-interactive nature must be visually unambiguous.
Warehouse filter dimension in the Orders List shows only their assigned location
All notifications are limited to activities related to their assigned location
Navigation
App open + valid session + Remember Me ON → Continue As screen → Dashboard
App open + no session → Login → Dashboard (or Access Denied for Inventory Manager)
Admin-revoked session → Login with session expiry message
Inventory Manager post-login → Access Denied screen; Log Out → Login screen
Log Out (confirmed) → Login screen
Back on Login screen → exits app
Acceptance Criteria
UI & Layout
On app open with no valid session, the Login screen should display an Email field, Password field, Remember Me toggle (defaulted to ON), and a Login button
Below the Login button, a supporting note should be displayed: 
"Your Browntape credentials are managed via the Ginesys SSO portal. To reset your password or update your account, visit the SSO portal."
 — with "SSO portal" as a tappable link to https://sso.ginesys.one/login
When "SSO portal" is tapped, it should open in the device's default browser
The Login screen should not display any forgot password flow, social login option, or biometric prompt
When an Inventory Manager successfully authenticates, the Access Denied screen should display a full-screen message — 
"
"Inventory not available on the mobile app. To manage inventory operations, please open Browntape using your desktop browser.”
."
 — and a Log Out button, with no navigation drawer, modules, or data loaded
When a Warehouse Manager is logged in, the Dashboard header should show a non-interactive location indicator with their assigned warehouse name — it must be visually unambiguous that it is not tappable
When a full-access role (Operations, Account Owner, Fulfillment Manager) is logged in, the Dashboard header should show an interactive location indicator displaying the currently active location — tapping it must open the Location Switcher
When a Warehouse Manager is logged in, the Locations filter dimension in the Orders List should show only their assigned location
Validation
When the Login button is tapped with the Email field empty, an inline error — 
"Email is required"
 — should appear below the Email field
When the Login button is tapped with the Password field empty, an inline error — 
"Password is required"
 — should appear below the Password field
When the Login button is tapped with both fields empty, both inline errors should appear simultaneously, not one at a time
When credentials are submitted and rejected by the SSO portal, an inline error — 
"Invalid email or password"
 — should be displayed
Auth & Session
On successful login, the session token should be stored in OS-level secure storage (Keychain on iOS, Keystore on Android)
Token refresh should be handled silently in the background without prompting the user to re-authenticate
Closing the app, backgrounding it, or restarting the device should not log the user out
When the session becomes invalid, the user should be redirected to the Login screen
When Remember Me is ON and the user opens the app after a previous session, the app should open directly to the Continue As screen
When Remember Me is OFF, the session should be cleared on app logout and full credentials should be required on next open
The Remember Me state should be stored per device
When a new login is completed with Remember Me ON, it should overwrite any previously saved Remember Me session — only the most recent login should be stored
When an Inventory Manager logs in, a Remember Me session should not be stored regardless of the Remember Me toggle state; on next app open they should be routed to the Login screen
When the user taps "Log in with a different account" and does not complete a new login, the previously saved session should remain intact
Roles & Permissions
When a user with the Operations, Account Owner, or Fulfillment Manager role logs in, they should have full access to all modules and see an interactive location indicator in the Dashboard header
When a Warehouse Manager logs in, they should have full access to all modules but all data should be scoped to their assigned warehouse only at the API level
When an Inventory Manager logs in, they should be routed to the Access Denied screen with no access to any module or data
Warehouse Manager location context should not be switchable in-app
The last selected location for full-access roles should be saved per user account and persist across devices
Business Logic
When the app is opened with a valid session and Remember Me ON, the user should be routed to the Continue As screen then to the Dashboard on Continue
When the app is opened with no valid session, the user should be routed to the Login screen, then to Dashboard or Access Denied based on role
When Log Out is confirmed, the session should be cleared and the user returned to the Login screen
When the Back button is pressed on the Login screen, the app should exit
When an Inventory Manager taps Log Out on the Access Denied screen, they should be returned to the Login screen
Device & Platform
When the Back button is pressed on the Login screen (Android), the app should exit rather than navigate to another screen


### BTA-16470: BT App: Implement Single-Session Enforcement and Session Conflict Flow

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16470

Background
Browntape user accounts should only be active on one device at a time. If a second device attempts login while a session is active elsewhere, the system must surface a clear conflict resolution flow — allowing the user to choose whether to displace the existing session.
Problem Statement
Without single-session enforcement, users could inadvertently maintain parallel sessions across devices, creating data integrity and security risks.
Objective
Enforce one active session per user account and provide a clear, informative conflict resolution flow when a second device attempts to log in.
Proposed Solution
The server enforces one active session per user account
When a login attempt detects an existing active session on another device, the server returns a session conflict response; login does not complete automatically
In the event of a simultaneous login race condition (two devices triggering "Sign in anyway" at the same moment), the server must resolve the conflict deterministically — 
last-write-wins based on server-received timestamp
 — and return the correct active session state to each device. No client-side resolution is needed.
Session Conflict Bottom Sheet (shown on Device 2 attempting to log in)
Warning icon
Message: _"Already logged in on another device. Only one active session is allowed per account. Your account is already active on another device. Signing in here will log them out."
Device card: model name of currently active device + last active time (e.g. 
"iPhone 14 Pro · Last active 8:54 AM"
). If the device model name cannot be resolved, the card displays "Unknown Device" alongside the last active time.
Last active timestamp format:
Scenario
Format
Today
"8:54 AM"
Yesterday
"Yesterday, 8:54 AM"
Older
"Apr 30, 8:54 AM"
Unknown device
"Unknown Device"
Two actions: 
"Sign in anyway"
 (primary) and 
"Cancel"
"Sign in anyway" Behaviour
Device 2 (signing in)
Device 1 (displaced)
Session
Receives a new session token
Session is revoked immediately
Screen
Navigates to Dashboard
Toast: 
"Your account was signed in on another device, so you've been logged out."
 → auto-dismiss after 4 seconds → transitions to Login or Continue As screen
Post-displacement behaviour on Device 1:
Remember Me ON → transitions to Continue As screen. Tapping "Continue" attempts re-authentication. If a conflict still exists, the Conflict Bottom Sheet is shown again with updated device details.
Remember Me OFF → transitions directly to Login screen; no Continue As screen
Push Notification on Displacement
When a session is displaced, a push notification is sent to the displaced user:
Title:
 Security Alert
Body:
 _"Your Browntape account was signed in on another device ({{Device Name}}). Your previous session has been logged out."
This notification is delivered regardless of the user's notification preferences — it is a security notification, not an order event.
Navigation
Login attempt + conflict detected → conflict bottom sheet
"Sign in anyway" → Dashboard (current device)
Displaced device, Remember Me ON → Continue As screen → Continue → (if no conflict) Dashboard; (if conflict persists) → conflict bottom sheet again
Displaced device, Remember Me OFF → Login screen
"Cancel" → user remains on Login screen
Acceptance Criteria
Given a user is logged in on Device 1 and attempts login on Device 2, the conflict bottom sheet is shown on Device 2 and login does not complete automatically
Given the conflict bottom sheet is shown, the device card displays the model name and last active time of the currently active device using the specified timestamp format
Given the device model name cannot be resolved, the device card should display "Unknown Device"
Given the user taps "Sign in anyway", Device 2 receives a new session token and navigates to Dashboard
Given the user taps "Sign in anyway", Device 1's session is revoked immediately and a toast — 
"Your account was signed in on another device, so you've been logged out."
 — is shown and auto-dismissed after 4 seconds
Given the user taps "Sign in anyway", a push notification is delivered to Device 1 with the message: _"Your Browntape account was signed in on another device ({{Device Name}}). Your previous session has been logged out."
Given Device 1 had Remember Me ON when displaced, it transitions to the Continue As screen after the toast dismisses
Given the user taps "Continue" on the Continue As screen and no conflict exists, the session resumes and navigates to Dashboard
Given the user taps "Continue" on the Continue As screen and a conflict still exists, the conflict bottom sheet is shown again with updated device details
Given Device 1 had Remember Me OFF when displaced, it transitions directly to Login with no Continue As screen
Given the user taps "Cancel" on the conflict bottom sheet, they remain on the Login screen with no session created
Given two devices simultaneously tap "Sign in anyway", the server resolves the conflict using last-write-wins based on server-received timestamp — no client-side resolution is required


### BTA-16479: BT App: Dashboard

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16479

Background
The Dashboard is the default landing screen after login. It surfaces today's key order metrics and provides one-tap entry into core workflows. The side navigation drawer is the global navigation mechanism accessible from any main screen. Both must work together to give users fast orientation and movement through the app.
Objective
Deliver a performant, role-aware Dashboard home screen with live order metric cards and quick-action tiles, alongside a fully functional side navigation drawer.
Proposed Solution
Side Navigation Drawer
Triggered by hamburger icon (top-left) on any main screen
Slides in from the left with a dark overlay on the rest of the screen
Dismissable by tapping outside or the close (X) icon
Drawer header: Browntape logo, logged-in user's name and email, close (X) button
Navigation items: Dashboard · Orders · Scan Picklist · Returns · Notifications · Settings
Active screen visually highlighted in the drawer list
Drawer footer: company/tenant info card · Log Out
Log Out triggers a confirmation dialog: 
"Are you sure you want to log out of Browntape?"
 with Cancel and Log Out options
Dashboard Header & Identity
Top bar: hamburger icon (top-left), Browntape logo centered
Time-aware greeting using the user's first name:
Time
Greeting
12:00 AM – 11:59 AM
"Good morning, {First Name}"
12:00 PM – 4:59 PM
"Good afternoon, {First Name}"
5:00 PM – 11:59 PM
"Good evening, {First Name}"
Location indicator — role-dependent behaviour:
The behaviour differs by role:
Full-access roles (Operations, Account Owner, Fulfillment Manager):
 Interactive location indicator in the Dashboard header showing the currently active location. Tapping it opens the Location Switcher. Must clearly signal that the location is switchable.
Warehouse Manager:
 Non-interactive location indicator showing the assigned warehouse name. Is not tappable. The non-interactive nature must be visually unambiguous.
Location switching is only available from the Dashboard — not from Orders List, Returns, or any other screen.
Order Status Overview
Four metric cards showing live counts:
Card
Status Description
Count Navigates To
New
Orders received today pending acceptance
Orders List filtered: New
Packing
Orders accepted and in progress
Orders List filtered: Packing
Ready to Ship
Packed orders awaiting pickup/handover
Orders List filtered: Ready to Ship
Returns
Returns pending action
Returns List
SLA Breached alert card:
 Full-width, shown only when count > 0. Navigates to Orders List filtered by SLA Breached. Disappears on next data refresh when count returns to zero.
Zero counts must always render
 — the layout must not collapse or skip a status because its count is zero
Quick Access to Key Workflows
Orders tile:
 shows pending order count; navigates to Orders List
Scan Picklist tile:
 subtext "Scan batch ID"; navigates to the 
Scan Picklist batch selection screen
 (not the camera directly)
Returns tile:
 subtext "QC and process"; navigates to Returns Home screen
Data Behaviour
All counts load with a visible skeleton/shimmer loading state; layout must not shift when data arrives
Pull-to-refresh
 reloads all counts
Counts auto-refresh when the user returns to Dashboard from any action screen
 — this is not the same as pull-to-refresh; it happens automatically
On fetch failure: show a non-data state (e.g. "—") with a retry option
When offline:
 last successfully fetched counts remain visible with a clear stale-data indicator. The full-screen offline takeover (see NFRs) does not suppress the stale counts — both should be visible simultaneously.
Zero counts must always render — never collapse or skip a status
Navigation
Default landing screen after login
Metric cards → Orders List filtered by status
SLA Breached card → Orders List filtered by SLA Breached
Quick action tiles → respective screens
Hamburger → drawer opens; nav item tap → navigate and close drawer; tap outside or X → close drawer
Log Out in drawer footer → confirmation → Login screen / Continue As screen
Back on Dashboard (Android) twice → exits the app
iOS swipe-back gesture disabled on Dashboard (root screen)
Acceptance Criteria
UI & Layout
On app launch after login, the Dashboard should be the default landing screen
The top bar should display a hamburger icon on the left and the Browntape logo centered
A time-aware greeting should display based on device time: "Good morning" (12 AM–11:59 AM), "Good afternoon" (12 PM–4:59 PM), or "Good evening" (5 PM–11:59 PM), followed by the logged-in user's first name
When the logged-in user's role is Warehouse Manager, the Dashboard header should show a 
non-interactive
 location indicator with their assigned warehouse name — it must be visually unambiguous that it is not tappable
When the logged-in user's role is Operations, Account Owner, or Fulfillment Manager, the Dashboard header should show an 
interactive
 location indicator displaying the currently active location — tapping it must open the Location Switcher
The Today's Orders section should display four metric cards: New, Processing, Ready to Ship, and Returns
Each metric card should display the card label, relevant count, and a status description
Zero counts must always render
 — the layout must not collapse a card because its count is zero
The SLA Breached alert card should be full-width and positioned below the metric cards
When the SLA Breached count is 0, the SLA Breached card should not be visible
When the SLA Breached count is greater than 0, the SLA Breached card should be visible and display the count
The Fulfillments section should display three tiles: "Orders" (with pending count), "Scan Picklist" (with subtext "Scan batch ID"), and "Returns" (with subtext "QC and process")
While data is loading, a skeleton loader should be shown in place of all metric cards and tiles
Data Behaviour
While data is loading, a skeleton/shimmer loading state must be shown; layout must not shift when data arrives
Pull-to-refresh must reload all counts
When the user returns to the Dashboard from any action screen, all counts must auto-refresh automatically — no user action required
When a data fetch fails, each affected card should show "—" with a retry option
When the device is offline, the last successfully fetched counts should remain visible with a clear stale-data indicator
Navigation & Interaction
Tapping a metric card should navigate to the Orders List filtered to that status (Returns card → Returns List)
Tapping the SLA Breached card should navigate to the Orders List filtered by SLA Breached
Tapping the Orders tile should navigate to the Orders List
Tapping the Scan Picklist tile should navigate to the Scan Picklist batch selection screen
Tapping the Returns tile should navigate to the Returns Home screen
Tapping the hamburger icon should open the navigation drawer
Tapping a navigation item in the drawer should navigate to that screen and close the drawer
Tapping outside the drawer or the X icon should close the drawer without navigating
Tapping Log Out in the drawer footer should show a confirmation dialog before logging out
On Android, pressing Back twice on the Dashboard should exit the app


### BTA-16462: BT App: Location Switcher for Full-Access Roles

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16462

Background
Operations, Account Owner, and Fulfillment Manager roles can access data across multiple store locations. The location switcher enables these users to change their active location context quickly and predictably. This is a critical module — orders, returns, and all metrics across the app reflect the currently selected location.
Objective
Deliver a fast, reliable location switcher accessible from the Dashboard header that supports recent locations and typeahead search, with predictable in-session and cross-session persistence behaviour.
Proposed Solution
Location Indicator
The currently active location must always be visible in the Dashboard header for full-access roles (Operations, Account Owner, Fulfillment Manager)
It must be interactive — tapping it opens the location switcher
The indicator must clearly signal that the location is switchable (e.g. a chevron or dropdown affordance) and display the current location name
Location switching is 
only available from the Dashboard
 — it is not accessible from the Orders List, Returns module, or any other screen
For Warehouse Managers, the location indicator is non-interactive and displays the assigned warehouse name only (see BTA-16469)
Location Switcher
The switcher supports two ways of finding a location:
Recently used locations
Shows the last 3–5 locations the user has accessed, in reverse chronological order
This section is hidden on first login when no history exists
For users who work across a small number of sites regularly, this list alone should cover most daily switching without needing to search
Search (typeahead)
Filters matching locations as the user types
Search must trigger with a minimum of 
2 characters
Must match on location name
If a location already appears in the recents list, it must 
not
 appear again in search results — no duplicates
There is no full list of all locations — the only way to find a location beyond recents is via search.
Dismissing the switcher without selecting a location makes no change to the active context.
Behaviour on Location Selection
Selecting a location always triggers a full data reload. There is no confirmation step. The behaviour is the same every time, regardless of in-session state.
On selection:
The active location updates immediately to the newly selected location
All Dashboard metrics reload
Any active filters or sort order in the Orders List are 
reset to their defaults
 — filters set for one location (e.g. a specific courier or channel) may be meaningless at another, and carrying them over creates a risk of acting on mismatched data
The selected location moves to the top of the recents list
Session Persistence
The last selected location is saved to the user's account
When the app is reopened, it resumes with the same location that was active at the end of the previous session — no prompt, no selection required
This persists 
across devices
 — if the user logs in on a different device, their last selected location carries over
Exception:
 If the previously selected location is no longer accessible (e.g. removed from the user's account by an admin), the app falls back to a default location and must inform the user that their previous location is no longer available
First Login
On first login, no location has been previously selected
The app defaults to the first location returned by the API for that user
Navigation
Tapping the location indicator in the Dashboard header → opens Location Switcher
Tapping a location in the switcher → selects it, reloads Dashboard data, moves location to top of recents, closes switcher
Tapping outside the switcher or dismissing → no change to active context
Location switcher is not accessible from any screen other than the Dashboard
Acceptance Criteria
Location Indicator
The location indicator must be visible in the Dashboard header for Operations, Account Owner, and Fulfillment Manager roles
The location indicator must display the name of the currently active location
The location indicator must clearly signal that it is interactive and the location is switchable
Tapping the location indicator must open the location switcher
The location switcher must not be accessible from any screen other than the Dashboard
Recents List
When the user has a recents history, the last 3–5 locations must appear in reverse chronological order
When the user has no recents history (first login or no prior selections), the recents section must be hidden entirely
After selecting a location, it must move to the top of the recents list
Search
The typeahead search input must be present in the switcher
Search must not trigger until at least 2 characters have been entered
Search must filter locations matching the typed name
A location that already appears in the recents list must not appear again in the search results
There must be no full list of all locations — locations beyond recents are only discoverable via search
Selection Behaviour
Selecting a location must immediately update the active location shown in the Dashboard header
Selecting a location must trigger a full reload of all Dashboard metrics
Selecting a location must reset any active filters and sort order in the Orders List to their defaults
Selecting a location must move that location to the top of the recents list
Dismissing the switcher without selecting a location must make no change to the active context
Session Persistence
The last selected location must be saved to the user's account
On app reopen, the previously active location must be resumed automatically — no prompt or selection required
The last selected location must persist across devices — logging in on a new device must restore the previously active location
When the previously selected location is no longer accessible, the app must fall back to a default location and display a message informing the user that their previous location is no longer available
On first login with no previously selected location, the app must default to the first location returned by the API


### BTA-16481: BT App: Build Order List 

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16481

Background
 
The Orders List is a core operational screen. The current browser-based experience forces a desktop layout on mobile, making it entirely unusable. A native mobile Orders List is critical for store users and warehouse staff to action orders on the go.
Problem Statement
 
Store users and warehouse staff cannot effectively view or manage orders on mobile today. The desktop layout breaks on mobile screens.
Objective
 
Deliver a usable, performant native Orders List screen with tabbed status views, search, filter, and sort capabilities.
Current Behavior
 
Order list page does not render properly on mobile browser. Desktop layout is forced on mobile making it unusable.
Proposed Solution
Status tabs:
 To Fix · New · Packing · Ready to Ship · Shipped 
Default active tab: 
New
To Fix tab — inline banner:
Non-dismissible banner at top: 
"
To fix the orders below, log in to Browntape via the desktop app
"
The to fix tab should have the search, sort and filter disabled
Search:
 
Is a global search and can be used to search any field. Similar to the web app.


Search is scoped to the currently active tab (not global across all tabs). 
Search triggers after the user stops typing for 400ms (debounce). 
Minimum 2character required to trigger a search. 
A clear (✕) icon appears inside the search field once the user begins typing; tapping it clears the field and resets the list to the unfiltered state. 
The mobile keyboard "Search" / "Done" action key also submits the search immediately. 
When search is active, the tab count badge reflects the filtered result count.
Filter:
Universal filter structure consistent with Browntape web app
The filter bottom sheet is triggered by tapping the Filter button. It slides up from the bottom with a drag handle at the top. The sheet header reads "Filters" with an "X" close icon on the right. Tapping outside the sheet or dragging it down dismisses it without applying changes.
Available filter fields (consistent with web app):
Date Range
 — date picker (From / To), Today, Yesterday, Last 7 days and Last 30 days
SLA / Dispatch By Date — 
date picker (From / To), Today, Yesterday
Financial Status
Channels
Order Type
Order Business Type
Invoice Status
Order Priority
ERP Fields
SKU
Product Family
Bottom sheet footer : two full-width buttons — Clear Filters  and Apply Filters. Filters are only applied when the user taps Apply — not in real-time as selections are made.
Multiple filters can be applied simultaneously
Clear Filters resets all active filters
When filters are active, a count pill is shown adjacent to the Filter button (e.g. 
"Filters · 3"
)
If many filters are applied then it shows a few tablets and +x more filters pill
Tapping the filter pills or the "+x more filters" pill should open the filter bottom sheet
Filter is active across all the tabs.
Clicking on the filter opens up the bottom sheet as seen above.
the two buttons for the filter at the end of the bottom sheet
Once the filter have been applied
It shows the first 3 filters plus more filters applied 
Sort:
Sort By accessible from the top bar alongside Filter
Options: Newest First (default), Oldest First,  High to Low,  Low to High
Active sort reflected in Sort button label by a highlight
Sort persists per tab until changed or screen closed
Sort selection persists for the duration of the app session only. When the user closes the Orders List screen and reopens it, sort resets to the default (Newest First) for all tabs. 
Sort does not persist across app restarts. 
Sort is tab-independent — changing sort on the "New" tab does not affect sort on "Packing."
Order cards show:
 customer name, payment badge, status badge, channel order ref, channel, order type, ship to, SKU, timestamp, SLA status, order total, shipping fees
More than 3 SKUs: first 3 shown with 
"+x more items"
 dropdown to expand
Tapping "+x more items" on an order card expands inline (not a modal or new screen) to show all SKUs for that order. 
The card height increases to accommodate the full list. A "Show less" link appears below the expanded list to collapse it back to the first 3 SKUs. 
Only one card can be expanded at a time — expanding a new card collapses the previously expanded one


To Fix tab: SKU shown as a red UNMAPPED pill for unmapped SKUs
List Loading — Infinite Scroll
The first 20 orders are fetched and rendered on tab open
As the user scrolls within 3–4 cards of the bottom of the list, the next batch of 20 orders is fetched silently and appended to the list
When all orders for the active tab have been loaded there is no further scroll down
When the user applies a search, filter, or sort change, the list resets to the first batch of 20 results for that query, with infinite scroll applying to the new result set
Pull-to-refresh resets the list and re-fetches from the first batch
Pull-to-refresh; empty state when no orders in tab




UI - Loading and Empty Screens
Skeleton Loading
 — shimmer cards while the first batch fetches
Empty Tab
 — no orders in this tab, with a pull-to-refresh nudge
Empty Search / Filter
 — no results for the query, with a "Clear search" action
Pull to Refresh
 — spinner bar visible with refreshing
Loading Next Page
 — spinner at the bottom as the next 20 load silently
End of List
 —  "All  orders loaded" footer
Navigation
Entry to the Order list: 
Drawer of Side navigation
Dashboard metric cards 
Dashboard Orders tile
Card tap → Order Processing screen
Exit: 
Back of phone→ Dashboard 
 Drawer → any main screen
Acceptance Criteria
UI & Layout
On opening the Orders List screen, five status tabs should be displayed: To Fix, New, Packing, Ready to Ship, Shipped — in that order
The New tab should be active by default when the screen is opened
When the To Fix tab is active, a non-dismissible inline banner should appear at the top of the list reading "
To fix the orders below, log in to Browntape via the desktop app”
The To Fix banner should not appear on any tab other than To Fix
Each order card should display: customer name, payment badge, status badge, channel order ref, channel, order type, ship to, warehouse, SKU(s), timestamp, SLA status, order total, and shipping fees
When an order has more than 3 SKUs, the card should show the first 3 SKUs and a "+x more items" link
Tapping "+x more items" should expand the card inline to show all SKUs for that order, with a "Show less" link below the expanded list
Tapping "Show less" should collapse the card back to showing only the first 3 SKUs
When a card is expanded, any previously expanded card should collapse automatically — only one card may be expanded at a time
On the To Fix tab, unmapped SKUs should be displayed with a red UNMAPPED pill
The search bar should display a clear (✕) icon inside the field once the user begins typing
When filters are active, a count pill (e.g. "Filters · 3") should appear adjacent to the Filter button
When filters are active, the first 3 applied filters should be shown as pills, with a "+x more filters" pill for any beyond the first 3
Tapping the filter pills or the "+x more filters" pill should open the filter bottom sheet
The active sort should be visually highlighted in the Sort button label
While the first batch of orders is fetching, shimmer skeleton cards should be displayed
When a tab has no orders, an empty state illustration should be shown with a pull-to-refresh nudge
When a search or filter returns no results, an empty state should be shown with a "Clear search" action
While the next page of orders is loading, a spinner should appear at the bottom of the list
When all orders for the active tab have been loaded, an "All orders loaded" footer should be displayed
While pull-to-refresh is in progress, a spinner/progress bar should be visible at the top of the list
The filter bottom sheet should slide up from the bottom with a drag handle at the top, a "Filters" header, and an "X" close icon on the right
The filter bottom sheet footer should contain two full-width buttons: "Clear Filters" and "Apply Filters"
Business Logic
The search should be scoped to the currently active tab — not across all tabs
Search should trigger only after the user has stopped typing for 400ms (debounce)
Search should not trigger unless at least 2 characters have been entered
When the ✕ icon is tapped, the search field should clear and the list should reset to the unfiltered state
Pressing the keyboard "Search" or "Done" action key should immediately submit the search without waiting for the debounce
Filters should only be applied when the user taps "Apply Filters" — filter selections should not update the list in real time
Tapping "Clear Filters" should reset all filter selections in the bottom sheet
Multiple filters should be applicable simultaneously
Tapping outside the filter bottom sheet, or dragging it downward, should dismiss the sheet without applying any changes
Sort options should be: Newest First (default), Oldest First, SLA: Soonest, Order Value: High to Low, Order Value: Low to High
Sort selection should be tab-independent — changing sort on one tab should not affect the sort on any other tab
Sort selection should persist for the duration of the session; closing and reopening the Orders List screen should reset sort to Newest First on all tabs
Sort should not persist across app restarts
The first 20 orders should be fetched and rendered when a tab is opened
When the user scrolls to within 3–4 cards of the bottom of the list, the next batch of 20 orders should be fetched silently and appended
When a search, filter, or sort change is applied, the list should reset to the first 20 results for the new query, with infinite scroll applying to the new result set
Pull-to-refresh should reset the list and re-fetch from the first batch
The filter bottom sheet should offer the following filter fields: Date Range, SLA / Dispatch By Date, Financial Status, Fulfillment Status, Channels, Location Type, Locations, Order Type, Order Business Type, Invoice Status, Order Priority, ERP Fields, SKU, Product Family
Date Range filter should support a From/To date picker and quick options: Today, Yesterday, Last 7 days, Last 30 days
SLA / Dispatch By Date filter should support a From/To date picker and quick options: Today, Yesterday
Device & Platform
Tapping the phone's back button from the Orders List screen should navigate the user to the Dashboard
The Orders List screen should be accessible from the side navigation drawer, dashboard metric cards, and the dashboard Orders tile
Tapping an order card should navigate the user to the Order Processing screen
Error Handling
If the initial order fetch fails, an error state should be displayed with a retry action
If a subsequent infinite scroll page fetch fails, a non-blocking error indicator should appear at the bottom of the list with a retry option, without disrupting the already-loaded list


### BTA-16480: BT App: Build Order Processing Screen

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16480

Background
Order Processing is the core action screen for managing individual orders on mobile. It must surface the correct information and actions based on the order's current state, with all irreversible actions feeling appropriately deliberate.
Objective
Deliver a fully functional Order Processing screen with four tabs, a role-aware persistent header, a dynamic bottom action bar driven by order lifecycle state, and complete support for all order line item types.
Proposed Solution
Screen Structure
Four tabs: 
Order Info · Shipping · Returns · Transactions
Horizontal swipe gestures may be used for switching between tabs
The Shipping tab is hidden when the order is in Pending Acceptance.
 The Returns tab is visible only when the order goes to the shipped status. The design must handle this gracefully — the user should understand shipping info is not yet available, not wonder if something failed to load.
Action buttons must be accessible regardless of which tab is active.
 If a user is on the Shipping tab and needs to accept the order, they must not need to navigate back to Order Info first.
Persistent Header (always visible regardless of tab or scroll)
The following must remain visible at all times:
Channel identifier and customer full name
Order creation date and time
Total item count and gross order value
Financial status (paid/unpaid)
Fulfillment status
Priority indicator where applicable — urgent/priority orders and hyperlocal orders must be 
visually distinguishable from each other
 and from standard orders
Partial fulfillment indicator, when applicable
Hop SLA countdown timer
 — shown only when the order is in Pending Acceptance and an SLA deadline exists; disappears once the order moves past Pending Acceptance
Financial status and fulfillment status are separate concerns and must be displayed as 
distinct, independently readable labels
 — not collapsed into a single indicator.
Order Info Tab
Always present regardless of fulfillment status.
Order details:
 Channel name, order type, channel order reference number, sub order ID. For orders on hold pending internal processes (e.g. PO generation), a clear notice must explain why the order cannot yet be actioned.
Order line items — two item types:
Standard items:
 quantity, SKU code, product name, product image, price (gross value and any discount), item reference, channel SKU code, channel product ID
Bundle items:
 A bundle has a parent SKU and one or more child SKUs.
Parent and children must be visually grouped with their relationship clear
Parent-level details must be accessible
Child SKUs must always be visible (not collapsible/optional)
Each child shows: quantity, SKU code, name, image, MRP, and references
Batch information:
 For batch-tracked items, the user must be able to view or add batch data directly from the item — only when batch tracking is enabled and the order is past Pending Acceptance. Items with batch data recorded and items where it is still outstanding must be clearly distinguished.
Tagloop reference:
 For specific order types, users must be able to enter and save a tagloop reference against an item.
Count of tagloop codes must match item quantity
Each code must conform to the required prefix
Validation errors must be shown clearly before the user can save
Overpick warning:
 If picked quantity exceeds ordered quantity, this must be prominently flagged on the affected item with a direct path to resolve the discrepancy.
Quantity to accept:
 Visible only in Pending Acceptance when partial rejection is enabled for the channel.
Per-item: accepted quantity and cancelled quantity must both be shown simultaneously so the user can verify before confirming
This control disappears once the order moves past Pending Acceptance
Post-acceptance item status:
 Once past Pending Acceptance, quantity controls are replaced by the outcome: accepted quantity, cancelled quantity, or a clear indicator if the item was fully cancelled. Read-only.
Order summary:
 Full financial breakdown accessible below the item list — shipping fee, COD fee, each discount line (identifying what it applies to and its type), and the final order total.
Rejection history:
 Shown only if the order has previously been rejected and re-routed. Each entry must show: when it occurred, which items were affected and at what quantity, the reason given, any additional comments, and whether it was a cancellation or a standard rejection. This history must not be buried.
Shipping Tab
Hidden in Pending Acceptance. Visible once the order moves past Pending Acceptance.
Tracking information: assigned courier and tracking number
Package details: dimensions (L × B × H) and weight
Pickup details
 — shown only for Amazon EasyShip order types: scheduled pickup date, time band, and ability to change the pickup slot. Must not appear for standard shipped orders.
Delivery address:
 full shipping address
Billing address
 — shown only when a billing address exists and is distinct from the shipping address. Must not appear as an empty section.
Packaging selection — configuration-driven:
Packaging opted for the channel:
Operator must select or scan packaging before RTS or Allocate Courier can proceed
Within the Package Details card: operator can choose from a dropdown (showing each option's short code) or scan a packaging barcode via scan icon
Once valid packaging is selected, the dropdown and scan option are both disabled and confirmed packaging details are shown: Selected Package title, Dimensions, Weight (packaging weight + order weight)
A 
Change
 option remains available until RTS or Allocate Courier is submitted — after which packaging is locked
Packaging error messages:
Scenario
Error message
Scanned packaging not in channel's opted list
"Invalid packaging selected. Please choose a valid packaging mapped to this channel."
Scanned packaging is inactive
"The scanned packaging is inactive in Packaging Management. Please activate it to proceed with selection."
Data recorded on submission: packaging ID, packaging dimensions (in mm), final order weight (order weight + packaging weight)
Packaging not opted for the channel:
 Standard behaviour applies. No packaging selection UI is shown.
Returns Tab
Visible only once the order is in Shipped Status.
Shows any return orders linked to this order
When no returns exist, a 
Create Return button
 must be prominently available for Manual Return Creation Supported Channel Types
If a default return warehouse is configured, this must be communicated to the user before they begin a return
Tapping Create Return navigates to the Create Return screen with the order pre-filled
Transactions Tab
Always visible, including in Pending Acceptance.
Initial transaction (auto-created on order placement) shows: Received At, Source, Source Reference Number, Gross Value, associated fees
Only Source and Source Transaction Reference are editable
 on the initial transaction. All other fields are read-only. The distinction must be immediately clear.
Users can record additional transactions for offline financial events (e.g. COD collection, manual adjustment)
User-created transaction entries must be 
visually distinct
 from the auto-created transaction
Actions & Order Lifecycle
The action bar is fixed at the bottom of the screen and updates automatically as the order moves through its lifecycle. 
Only actions valid for the current state are shown.
 The user must never be left in a state where an action appears but cannot be taken.
Pending Acceptance
Accept Full Order
 — used when partial rejection is not permitted on the channel. Accepts the entire order.
Accept Selected Qty
 — used when partial rejection is permitted. Operator adjusts per-item quantities on each item card, then taps this button. Both accepted and cancelled quantities must be visible simultaneously per item.
Because acceptance triggers background processing, the interface shows a loading state while the operation completes. The operator receives a clear success or failure notification once it resolves. If the system does not hear back after a reasonable number of retries, the loading state is dismissed and the order is refreshed — the operator is never left waiting indefinitely.
Reject Full Order
 — opens a rejection form where the operator selects a reason from a company-configured list. If the company requires a reason, the form cannot be submitted without one. Before finalisation, a 
confirmation screen is shown
 — the operator must confirm intent a second time to prevent accidental rejections.
Scan & Accept
 — when the Scan & Accept feature is enabled for the company, a barcode scanner input appears above the action buttons. The operator activates the device camera to scan product barcodes during picking, recording which physical batch or lot was picked. Feedback is shown immediately after each scan. In 
forced scan mode
, the Accept button remains disabled until all items have been scanned.
Processing / Packing (after acceptance, before shipment)
Mark as Ready to Ship
 (marketplace channels) — notifies the marketplace the order is packed and ready for courier collection. If packaging is opted for the channel, a valid packaging selection must be confirmed before this action can proceed. The operator receives confirmation once the channel is updated in the background.
Assign Courier
 (non-marketplace / webstore channels) — operator selects a courier from a real-time fetched list and optionally enters an AWB tracking number (auto-assigned if blank). A loading state is shown while booking is processed. If packaging is opted for the channel, a valid packaging selection must be confirmed before this action can proceed.
If 
Auto Courier Allocation
 is enabled for the company, courier selection is handled automatically — no manual selection is required and the dropdown is replaced with a status indicator confirming auto-allocation is active.
More Actions
 — secondary actions including the ability to reject the order after acceptance.
Processing / Packing — with tracking number already assigned
Process Order
 — triggers the marketplace update. Available for marketplace channels only.
More Actions
 — secondary actions.
Ready to Ship / Courier Assigned
Print Docs
 — generates and downloads shipping labels and order documents. Processing happens in the background; the operator is notified when the PDF is ready.
Add to Manifest
 — adds the order to a courier pickup manifest. Only shown if the order has not already been added to a manifest.
More Actions
 — secondary actions.
Rejecting After Acceptance (via More Actions)
When selected, the rejection interface replaces the order view entirely.
Full Rejection:
 A reason must be selected. A confirmation screen is shown before the rejection is submitted.
Partial Rejection:
 For each item being rejected, the operator specifies quantity and reason. At least one item must have a non-zero rejection quantity — the form cannot be submitted otherwise. Before final confirmation, the operator sees a clear summary of which items are being fulfilled and which are being rejected.
Error Handling
Silent failures are not acceptable. If an action does not complete successfully, the user must know.
For async actions, the interface must communicate that processing is in progress and confirm or report failure once resolved.
The user must not be able to trigger the same action twice while one is already in flight.
Navigation
Entry: order card tap from Orders List · notification tap · WhatsApp deep link
Sub-tab taps switch panel within the screen
Back → Orders List on the tab the order came from
Acceptance Criteria
Screen Structure
When the Order Processing screen loads, it should display four sub-tabs: Order Info, Shipping, Returns, Transactions
The Shipping tab should be hidden when the order is in Pending Acceptance; it should become visible once the order moves past Pending Acceptance
When the Shipping tab is hidden in Pending Acceptance, the remaining tabs must communicate its absence gracefully (not appear broken)
Action buttons must be visible and tappable regardless of which tab is currently active
The active sub-tab should be visually distinguished from inactive tabs at all times
Persistent Header
The persistent header must remain visible at all times regardless of active tab or scroll position
The header must display: channel identifier, customer full name, order creation date and time, total item count, gross order value, financial status, and fulfillment status
Financial status and fulfillment status must be displayed as distinct, independently readable labels — not combined into a single indicator
When the order has a priority flag, the header must visually distinguish between urgent/priority orders, hyperlocal orders, and standard orders
When a partial fulfillment indicator applies, it must be shown in the header
When the order is in Pending Acceptance and an SLA deadline exists, a Hop SLA countdown timer must be shown in the header
When the order moves past Pending Acceptance, the Hop SLA countdown timer must disappear
Order Info Tab
The Order Info tab should display channel details, order type, and channel order reference
For orders on hold pending internal processes, a clear notice must explain why the order cannot be actioned
Standard items must show: quantity, SKU code, product name, product image, price (gross value and discount), item reference, channel SKU code, channel product ID
Bundle items must be visually grouped showing parent and child SKUs; child SKUs must always be visible; each child must show quantity, SKU code, name, image, MRP, and references
For batch-tracked items past Pending Acceptance, the user must be able to view or add batch data directly from the item card; recorded and outstanding batch data must be clearly distinguished
For applicable order types, tagloop reference entry must be available per item; validation must enforce code count = item quantity and correct prefix; errors must be shown before saving is permitted
When picked quantity exceeds ordered quantity, an overpick warning must be prominently shown on the affected item with a path to resolve
When the order is in Pending Acceptance and partial rejection is enabled for the channel, per-item quantity controls must show accepted quantity and cancelled quantity simultaneously
When the order moves past Pending Acceptance, quantity controls must be replaced with the outcome: accepted qty, cancelled qty, or fully cancelled indicator (read-only)
The full financial breakdown (shipping fee, COD fee, each discount line with description, final total) must be accessible below the item list
When the order has previously been rejected and re-routed, a rejection history section must be visible showing: timestamp, affected items and quantities, reason, comments, and rejection type
The entire Quantity to Accept row must render on a single horizontal line with no wrapping
Accepted Qty and Cancelled Qty must display inline: 
Accepted Qty: X | Cancelled Qty: Y
Shipping Tab
When visible, the Shipping tab must show: tracking information, package dimensions, delivery address
Pickup details (date, time band, change slot option) must be shown only for Amazon EasyShip order types
Billing address must be shown only when it exists and differs from the shipping address; it must not appear as an empty section
When packaging is opted for the channel, a packaging selection (dropdown + scan option) must be present before RTS or Allocate Courier can proceed
Once valid packaging is selected, the dropdown and scan option must be disabled and confirmed details displayed
A Change option must remain available until RTS or Allocate Courier is submitted, after which packaging is locked
Scanned packaging not in the channel's opted list must show the error: "Invalid packaging selected. Please choose a valid packaging mapped to this channel."
Scanned inactive packaging must show the error: "The scanned packaging is inactive in Packaging Management. Please activate it to proceed with selection."
When packaging is not opted for the channel, no packaging selection UI should be shown
Returns Tab
The Returns tab must be visible in all order states including Pending Acceptance
When returns exist, each return linked to the order must be shown
When no returns exist and the channel supports Manual Return Creation, a Create Return button must be prominently visible
If a default return warehouse is configured, this must be communicated to the user before they begin a return creation flow
Transactions Tab
The Transactions tab must be visible in all order states including Pending Acceptance
The initial auto-created transaction must display: Received At, Source, Source Reference Number, Gross Value, and associated fees
Only Source and Source Transaction Reference must be editable on the initial transaction; all other fields must be read-only; the distinction must be visually unambiguous
User-created transactions must be visually distinct from the auto-created transaction
Users must be able to record additional offline transactions (e.g. COD collection, manual adjustment)
Action Bar
The action bar must be fixed to the bottom of the viewport at all times
Button widths in the action bar must be equal and adapt to screen width
Only actions valid for the current order state must be shown
In Pending Acceptance (no partial rejection): Accept Full Order and Reject Full Order must be shown
In Pending Acceptance (partial rejection enabled): Accept Selected Qty and Reject Full Order must be shown
When Scan & Accept is enabled, a barcode scanner input must appear above the action buttons; in forced scan mode, the Accept button must remain disabled until all items have been scanned
Acceptance must show a loading state during background processing; if no response after retries, loading must be dismissed and order refreshed
Reject Full Order must require reason selection (if company-configured) and a second confirmation screen before submission
In Processing/Packing (marketplace, no tracking number): Mark as Ready to Ship must be shown; packaging validation must occur before submission if opted
In Processing/Packing (non-marketplace, no tracking number): Assign Courier must be shown; when Auto Courier Allocation is enabled, the dropdown is replaced with a status indicator; packaging validation must occur before submission if opted
In Processing/Packing (tracking number assigned): Process Order must be shown (marketplace only)
In Ready to Ship: Print Docs and Add to Manifest (if not already manifested) must be shown
More Actions must be accessible alongside primary actions in Processing/Packing and Ready to Ship states
Full and Partial rejection after acceptance must be accessible via More Actions; the rejection interface must replace the order view entirely
Partial rejection after acceptance requires at least one item with a non-zero rejection quantity before submission; a summary of fulfilled vs rejected items must be shown before final confirmation
The user must not be able to trigger the same action twice while one is already in flight
Action Bar Layout Fixes
All buttons in the action bar must share equal width, dividing available screen width evenly
The action bar must be anchored to the bottom of the viewport (fixed position) at all times
All fields within a return details card on the Returns tab must follow a consistent two-column layout; no row should ever render three columns
The "Powered by Browntape" footer must be removed


### BTA-16486: BT App: Return Module -Acknowledgement, QC, Create and View Returns

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-29 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16486

Background
Returns processing encompasses several distinct but tightly related workflows: a home screen for orientation and navigation, an acknowledgement flow for confirming receipt, a QC flow for inspecting items and capturing photo/video evidence, a list view for browsing all returns, and a create return flow. All of these currently require desktop access. Bringing them to mobile enables warehouse staff to action returns entirely on the floor.
Objective
Deliver all five returns surfaces — Home, Acknowledgement, QC (with full media capture), View Returns List, and Create Return — as a cohesive mobile-native module.
Proposed Solution
Returns Home Screen
Four full-width action tiles:
Tile
Badge
Destination
View All Returns
None
View Returns List
Perform QC
QC Pending count (amber)
QC flow
Acknowledge Returns
Pending ACK count (red)
Acknowledgement flow
Create Return
None
Create Return flow
A zero count and a non-zero count on Perform QC and Acknowledge Returns tiles must communicate different things visually
All counts refresh on pull-to-refresh and when the user returns to this screen after completing an action
Return Acknowledgement Workflow
The "Acknowledge Returns" header with a back arrow must persist across all steps. No Browntape logo or footer branding anywhere in this flow.
Step 1 — Select Channel and Warehouse
Two selectors: Select Channel and Select Warehouse
Both required before proceeding
Warehouse is pre-populated by default
If the 
Show Return OTP without Acknowledgement
 setting is enabled in company return settings, a 
Get OTP button
 appears directly on this screen, regardless of whether the user completes the acknowledgement flow
Step 2 — Scan or Search Returns
Once channel and warehouse are set, user adds returns via:
Scan AWB / Return ID (barcode scanner — primary)
Search and Acknowledge (manual text entry — fallback)
A list of added returns appears below, initially empty
A live count of returns added so far is shown and updates in real time
The Complete Scanning button is disabled until at least one return has been added
Step 3 — Scanner
Camera opens with a visible barcode alignment guide
Scan is automatic on detection — no confirm tap required
On each successful scan: return added to list immediately, visual and haptic confirmation, scanner stays open for next scan
Inline scan errors (scanner stays open):
Situation
Feedback
Barcode already in the list
"Already added"
Barcode not recognised
"Return not found — try manual entry"
Step 4 — Multiple Returns
If the order contains 2 or more returns, a pop-up appears showing: channel, channel return ref, return type, AWB number, and order ref for each return
User selects the appropriate return and taps Select Return
Step 5 — Complete Scanning
User taps Complete Scanning; a summary screen appears showing: Channel Return Ref, Channel, Return Type, AWB, Order Ref
Two actions: Save and Acknowledge (primary) and Back to return to the list and continue scanning
Step 6 — Save and Acknowledge
For OTP channels: a pop-up appears showing channel name, courier name, number of returns acknowledged, and the OTP
The OTP is the most critical piece of information on this screen — it must be immediately readable
This pop-up is not dismissible via back; user must tap Share OTP or Close
Step 7 — Acknowledgement Complete
Success confirmation shown
User taps Close and is returned to Step 1 with channel, warehouse, and batch list fully reset
Back Navigation Table:
Step
Situation
Back action
Result
Step 2
List has items
Back
Confirm discard prompt before exiting
Step 2
List is empty
Back
Returns to Returns Home
Step 3
Scanner open
Close
Returns to Step 2, list unchanged
Step 5
Summary screen
Back
Returns to Step 2, list preserved
Step 6
OTP pop-up
—
Not dismissible via back
Step 7
Success
Close
Returns to Step 1, state reset
Return QC Workflow
The "Return QC" header with back navigation must persist throughout. No Browntape logo or footer branding on any screen within this flow.
If the app is backgrounded mid-QC (e.g. a call is received), all QC state in progress must be preserved when the user returns.
Context and channel selection
User's warehouse is pre-set and cannot be changed within this flow
An optional channel selector is available to filter by channel before scanning
Scanning a return
User adds a return via barcode scan (primary) or manual entry of Order ID or AWB (fallback)
Media capture — configuration-driven (three distinct behaviours):
Configuration 1 — Video mode, Auto Start Recording ON
As soon as a return is scanned, the camera opens immediately for video recording 
before
 order details or the item list are shown
A countdown runs before recording begins; the return reference must be visible during countdown so the user can confirm the correct return
Recording starts automatically once the countdown ends
During recording: elapsed time and time remaining must be visible
Maximum recording duration = 90 seconds for up to 2 items + 45 seconds for each item beyond 2
A clear warning must appear when 5 seconds remain
Recording stops automatically at the time limit
User may stop early but must explicitly confirm before the recording is saved and closed
The item QC list must not appear until recording is fully complete
Configuration 2 — Video mode, Auto Start Recording OFF
The item QC list is shown immediately after scanning, but all QC actions are 
disabled
 until a video has been recorded
A clearly visible prompt must communicate that recording must be started before QC can proceed
User initiates recording manually (no pre-countdown)
Same duration rules, live indicators, and early-stop confirmation apply
QC actions become enabled once recording is complete
Configuration 3 — Images Only mode
Video recording does not apply
The item QC list is shown immediately after scanning and all QC actions are available from the start
The Auto Start Recording setting has no effect in this mode
Return order details (before inspecting items)
User must be able to see: channel return reference, order reference, AWB, channel, return date, customer name, and the full item list with current QC status
All items show as Pending on first load
A 
progress indicator
 must be visible throughout showing items reviewed vs. total (e.g. "2 of 4"), updating in real time
Scanning an item
User scans the product barcode (auto-capture on detection) or manually enters the SKU
Once identified, item details shown: SKU, product name, colour, size, current QC status, serial or batch number if applicable, any bad condition reason, media fields, product image, and bundle information if applicable
QC decisions — three outcomes per item:
Good condition:
 Item passes QC. User confirms. Item updates to QC Passed and progress indicator advances.
Bad condition:
 Item fails QC. Before submitting, user must provide:
Reason:
 selected from configured bad condition reasons (e.g. damaged in transit, wrong item, item used/worn). A reason must be selected before submission.
Image capture:
 Up to 5 images per item, captured directly or from gallery. Running count of captured images must be visible. Once the limit is reached, further capture is prevented. Images can be reviewed and individually discarded 
before tagging
.
Image tagging:
 Every captured image must be assigned a tag (e.g. Front, Back, Damage, Label) before submission. 
Once tagged, an image cannot be deleted
 — this protects evidence integrity. Submission is disabled until all images are tagged. Validation enforced in real time.
Once submitted, item updates to QC Failed.
Item not received:
 Item was not present in the return shipment. User confirms. Item updates to Missing.
Editing a QC decision:
After a decision is recorded, the user must be able to correct it
Changing to Bad reopens the bad condition details flow
Changing to Good or Not Received requires a confirmation step only
Completing the QC session:
Once every item has been reviewed (none remain Pending), the user must be 
prompted
 to confirm completion — this must not happen automatically
After successful submission, user is returned to the scan screen
Back navigation:
Back tapped during QC with partially reviewed items → confirm discard before exiting
On QC completion → user returned to the scan screen, not to Returns Home
Returns List
Two tabs: 
All · Return QC Pending
Global search across all fields on return cards
Filter available for: 
Return Type, Return Status, Courier Status
Pull-to-refresh; empty state when no returns match search/filter
Back → Returns Home
Return card fields: channel, return status, transit status, Channel Return Ref, Return Type, Courier, AWB, SKU tags, Return Created timestamp
Per-card actions: 
Acknowledge
 (red outline) and 
Perform QC
 (green) — tapping either routes the user into the respective workflow for that specific return.
Create Return
Two-phase screen. Phase 1 (Find Order) visible on load. Phase 2 (Return Details + Item Selection) revealed only after a valid order is found.
A sticky 
Create Return button
 is always present at the bottom — disabled until all required conditions are met.
Phase 1 — Find Order
Search Type dropdown: BT Order ID · Channel Order ID · AWB Number (updates input placeholder dynamically)
Empty input on Search tap → toast: "Please enter an order ID"; no state change
Valid order found → Order Found card replaces empty state; Phase 2 revealed
Order Found card: channel (with icon), status badge, Channel Order ID, optional Return Warehouse dropdown
If a default return warehouse is configured, 
this must be communicated to the user
 before they begin a return
Order not in Shipped status → inline error: "Create return is not allowed for orders in status [status name]"; Phase 2 and Create Return button remain hidden
Phase 2 — Return Details
Field
Mandatory
Return Type
Yes
Return Reason
Yes
Return Courier
No
Return AWB No.
No
Channel Return Ref
No
At least one item selected
Yes
When Return Type = Courier Return: Return Reason populates with courier-specific reasons; Courier Name and AWB are auto-filled from the order and locked to read-only
Select Items card: checklist of all SKUs on the order. Each row: SKU pill, product description, truncated Channel Item ID, previous return quantity
Create Return button enables only when: Return Type selected + Return Reason selected + at least one item checked. Validation runs in real time.
On successful submission: toast "Return created successfully" → navigates to Returns Home after 1.2 seconds
Edge case — Return Type changed mid-flow:
 When Return Type is changed from Courier Return to a non-Courier type, auto-filled AWB and Courier fields must 
clear and become editable
.
Navigation
Entry to Returns Home:
 Drawer navigation · Dashboard Returns metric card · Dashboard Returns tile
Acknowledgement flow:
 Scan → Complete Scanning → Summary → OTP → Success → Step 1 reset
QC flow:
 QC Home → AWB Scan → Return Order Details → Item Barcode Scan → Item QC → Good / Bad / Missing → Complete → scan screen
View Returns List:
 Entry from View All Returns tile; Acknowledge/Perform QC on card → respective flow; Back → Returns Home
Create Return:
 Entry from Create Return tile; Back → Returns Home
Global:
 Back from any returns screen → Returns Home; Drawer → selected main screen
Acceptance Criteria
Returns Home Screen
On load, the home screen should display four full-width action tiles: View All Returns, Perform QC, Acknowledge Returns, and Create Return
The Perform QC tile should display a QC Pending count badge; a zero count and a non-zero count must communicate different things visually
The Acknowledge Returns tile should display a Pending ACK count badge; same zero vs. non-zero distinction applies
View All Returns and Create Return tiles should display no badge
When the user pulls to refresh, all tile counts should reload
When the user returns to the Returns Home after completing an action in any sub-flow, all counts should reload automatically
Return Acknowledgement Flow
The "Acknowledge Returns" header with a back arrow must be present throughout the entire flow
The Browntape logo must not appear in the header on any screen in this flow
The "Powered by Browntape" footer must not appear on any screen in this flow
Return QC tab must not be visible from within this flow
Step 1 must show two selectors: Select Channel and Select Warehouse; both must be required before proceeding; warehouse must be pre-populated by default
When the Show Return OTP without Acknowledgement setting is enabled, a Get OTP button must appear on the channel/warehouse selection screen (Step 1)
Step 2 must show a live count of returns added so far, updating in real time
The Complete Scanning button must be disabled until at least one return has been added
Scanner must open with a visible barcode alignment guide; scan must be automatic on detection
On each successful scan, the return must be added to the list immediately with visual and haptic confirmation; the scanner must remain open
When a barcode is already in the list, inline feedback "Already added" must appear without closing the scanner
When a barcode is not recognised, inline feedback "Return not found — try manual entry" must appear without closing the scanner
When an order has 2 or more returns, a pop-up must show: channel, channel return ref, return type, AWB number, and order ref for each return, with a Select Return action
The summary screen (Step 5) must show: Channel Return Ref, Channel, Return Type, AWB, Order Ref with Save and Acknowledge (primary) and Back actions
For OTP channels, the OTP must be displayed prominently in a pop-up showing channel name, courier name, number of returns acknowledged, and OTP
The OTP pop-up must not be dismissible via back; user must tap Share OTP or Close
On success, the user must be returned to Step 1 with channel, warehouse, and batch list fully reset
Back navigation must follow the table in the proposed solution section
Return QC Flow
The "Return QC" header with back navigation must be present throughout the entire flow
The Browntape logo must not appear in the header on any screen in this flow
The "Powered by Browntape" footer must not appear on any screen in this flow
Acknowledge Returns tab/flow must not be accessible from within this flow
When the app is backgrounded mid-QC, all QC state must be preserved on return
User's warehouse must be pre-set and not changeable within the flow; an optional channel selector must be available
Configuration 1 (Video, Auto Start ON):
When a return is scanned, the camera must open immediately for video recording before order details or item list are shown
A countdown must run before recording begins; the return reference must be visible during countdown
Recording must start automatically once the countdown ends
Elapsed time and time remaining must be visible during recording
The maximum recording duration must be: 90s (for ≤2 items) + 45s per additional item
A warning must appear when 5 seconds remain
Recording must stop automatically at the time limit
The user may stop early but must explicitly confirm before the recording is saved
The item QC list must not appear until recording is fully complete
Configuration 2 (Video, Auto Start OFF):
The item QC list must be shown immediately after scanning, but all QC actions must be disabled until a video has been recorded
A clearly visible prompt must communicate that recording must be started before QC can proceed
The user initiates recording manually (no pre-countdown)
Same duration rules, 5-second warning, and early-stop confirmation apply
QC actions must become enabled once recording is complete
Configuration 3 (Images Only):
Video recording must not apply; the Auto Start Recording setting has no effect
The item QC list must be shown immediately after scanning and all QC actions must be available from the start
QC decisions:
A progress indicator must be visible throughout showing items reviewed vs. total (e.g. "2 of 4"), updating in real time
Good condition: user confirms; item updates to QC Passed; progress indicator advances
Bad condition: user must provide a reason (required) and up to 5 images; each image must be assigned a tag before submission; once tagged, an image cannot be deleted; submission is disabled until all images are tagged
Item not received: user confirms; item updates to Missing
After a decision is recorded, the user must be able to change it; changing to Bad reopens the bad condition flow; changing to Good or Not Received requires confirmation only
Once all items have been reviewed (none Pending), the user must be prompted to confirm completion — this must not happen automatically
After successful submission, user is returned to the scan screen
Back tapped during QC with partially reviewed items → confirm discard prompt must appear
Returns List
The list must display two tabs: All and Return QC Pending
The search bar must function as a global search across all fields on the return cards
Filter must be available for: Return Type, Return Status, and Courier Status
Each return card must display: channel, return status, transit status, Channel Return Ref, Return Type, Courier, AWB, SKU tags, and Return Created timestamp
Each return card must display an Acknowledge button and a Perform QC button
Tapping Acknowledge on a card must take the user into the Ack flow for that specific return
Tapping Perform QC on a card must take the user into the QC flow for that specific return
Pull-to-refresh must reload the list
When no returns match the current search or filter, an empty state must be shown
Back must return the user to Returns Home
Create Return
On load, only Phase 1 (Find Order) should be visible; Phase 2 should be hidden
The Search Type dropdown must offer three options: BT Order ID, Channel Order ID, AWB Number; changing it must update the input placeholder
Empty input on Search tap must show a toast "Please enter an order ID" with no state change
When a valid order is found, an Order Found card must appear and Phase 2 must be revealed
The Order Found card must show: channel (with icon), status badge, Channel Order ID, and an optional Return Warehouse dropdown
If a default return warehouse is configured, this must be communicated to the user before they begin creating a return
When the order is not in Shipped status, an inline error "Create return is not allowed for orders in status [status name]" must appear and Phase 2 must remain hidden
Return Type and Return Reason are mandatory
When Return Type = Courier Return, Return Reason must populate with courier-specific reasons and Courier Name and AWB must be auto-filled and locked to read-only
When Return Type is changed from Courier Return to a non-Courier type, auto-filled AWB and Courier fields must clear and become editable
The Select Items card must list all SKUs on the order, each showing: SKU pill, product description, truncated Channel Item ID, and previous return quantity
The Create Return button must be disabled by default; it must become active only when Return Type, Return Reason, and at least one item are all selected
Validation must run in real time on every change, without a separate check step
On successful submission, a toast "Return created successfully" must appear and the user must be navigated to Returns Home after 1.2 seconds


### BTA-16463: BT App: Scan Picklist

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16463

Background
The Scan Picklist module is a digital picking assistant for warehouse and store staff. When orders need to be fulfilled, floor staff physically walk the shelves to collect items — this module guides them through that process step by step, using a barcode scanner as the primary input. It functions as a live digital checklist that updates itself as items are scanned.
This module is designed specifically for 
non-WMS ERP clients
 managing warehouse or store fulfillment without a dedicated Warehouse Management System. It will only be visible to eligible non-WMS ERP users. Clients using the Ginesys WMS will not see or have access to this option, as picking operations for those users are managed within the WMS workflow.
Objective
Deliver a mobile-native Scan Picklist module covering batch selection, item scanning, bundle and lot handling, order rejection, and session completion — with a concurrent session lock to prevent duplicate picking.
Proposed Solution
Batch Selection
Before scanning begins, the operator selects which batch — a group of orders — they are picking for this session.
A batch can be selected in one of two ways:
Scanning the barcode
 on a printed picklist sheet
Choosing from a list
 of available batches displayed on screen
Each batch in the list shows a status badge:
Badge
Meaning
Pick Pending
No items in this batch have been picked yet
Partially Picked
Some items have been scanned, but not all
Fully Picked
All items in this batch have been confirmed
The operator may select 
one or more batches
 to work on in a single session. Once their selection is made, they tap 
Start Scanning
 to proceed.
Concurrent session lock:
 A batch can only be actively scanned by one operator at a time. If a user has already started a scanning session for a batch, other users will not be allowed to perform picking actions on the same batch until the session is completed or released. The system must clearly indicate that the batch is currently in use by another operator.
Scanning Screen
This is the primary working screen. The operator scans item barcodes one at a time using a handheld scanner or the device camera.
On each successful scan:
The item is identified and displayed with its name and product image
A per-item counter updates to show how many units have been scanned against how many are required (e.g. "2 of 3 picked")
The corresponding order's progress updates in real time
All orders in the selected batch are visible on this screen. As items are scanned, each order fills toward completion. When all items in an order have been confirmed, the order is 
automatically marked as fully picked and removed from the active queue
 — no additional tap required.
Bundle / Kit Products
Some products are sold as a set, where each component has its own barcode. The operator can scan either an individual component or the kit as a whole. The screen must clearly distinguish which components within a kit have been scanned and which remain outstanding.
Batch / Lot Number Capture
For products that require lot-level traceability (e.g. food, pharmaceuticals, or expiry-date-tracked goods), scanning an item triggers a prompt requiring the operator to enter or scan the batch/lot code before the pick is recorded. This step 
cannot be skipped
 for affected items.
Rejecting an Order
If an item is damaged, missing, or out of stock, the operator can reject the order from within the scanning screen. Two modes are supported:
Full rejection:
 The entire order is cancelled. The operator selects a reason from a configured list.
Partial rejection:
 Specific items within the order are rejected. The operator selects which items and provides a reason for each. At least one item must be rejected for the submission to be valid.
The rejection trigger must be clearly accessible without being easy to activate accidentally.
Completion
When all items across all orders in the session have been scanned and confirmed:
Each order is 
automatically accepted
 — no separate acceptance step needed
For orders requiring courier shipment, 
pickup is arranged automatically
 in the background
The operator does not need to take any further action per order
Once the operator has finished scanning, they tap 
Complete
 to end the session. They are returned to the Batch Selection screen, ready to begin the next batch.
Navigation
Entry: Dashboard Scan Picklist tile · Side navigation drawer
Batch Selection → Start Scanning → Scanning screen
Scanning screen → Complete → Batch Selection screen
Rejection flow accessible from within Scanning screen
Back from Batch Selection → Dashboard
Acceptance Criteria
Batch Selection
The Batch Selection screen must allow batch selection via barcode scan of a printed picklist sheet
The Batch Selection screen must display a list of available batches, each with a status badge: Pick Pending, Partially Picked, or Fully Picked
The operator must be able to select one or more batches before starting a session
The Start Scanning button must be disabled until at least one batch is selected
Tapping Start Scanning must navigate to the Scanning screen
When a batch is already being actively scanned by another operator, the system must clearly indicate that the batch is in use and prevent the current user from starting a picking session on it
Scanning Screen
On each successful barcode scan, the item must be identified and displayed with its name and product image
A per-item counter must update to show units scanned vs. units required (e.g. "2 of 3 picked")
The corresponding order's progress must update in real time after each scan
All orders in the selected batch must be visible on the scanning screen
When all items in an order have been confirmed, the order must be automatically marked as fully picked and removed from the active queue without any additional tap
For bundle/kit products, the screen must clearly show which kit components have been scanned and which remain outstanding
The operator must be able to scan either an individual kit component or the kit as a whole
For batch/lot-tracked products, scanning an item must trigger a prompt for the operator to enter or scan the batch/lot code before the pick is recorded; this step must not be skippable
Rejection
A rejection trigger must be accessible from the Scanning screen
The rejection trigger must be clearly accessible but not easily activated accidentally
Full rejection must allow the operator to cancel the entire order with a reason selected from a configured list
Partial rejection must allow the operator to select specific items to reject, each with a reason; at least one item must be rejected for the submission to be valid
Completion
When all items across all orders in the session have been scanned and confirmed, a Complete button must be available
Tapping Complete must end the scanning session and return the operator to the Batch Selection screen
On session completion, each fully picked order must be automatically accepted without a separate acceptance step
For orders requiring courier shipment, pickup must be arranged automatically in the background on completion
Error Handling
An unrecognised barcode scan must produce inline feedback; the scanner must remain active
A batch load failure must show a meaningful error state with a retry option
A submission failure on session complete must clearly inform the operator; the session must not close silently on failure
Access Control
The Scan Picklist module must only be visible to non-WMS ERP clients
Clients using the Ginesys WMS must not see or have access to this module


### BTA-16490: BT App: Notification and Notificaiton Setting

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-29 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16490

Background
Users currently have no real-time alerting for new orders, cancellations, or auto-rejection events. New events are only visible when the user manually opens and refreshes the OMS. Additionally, some users receive order notifications via WhatsApp — tapping those links should open the relevant order directly in the app. This story covers the full notifications surface: push delivery, in-app inbox, user preferences, mute window, and deep link routing.
Objective
Deliver reliable push notifications for new orders, cancellations, and auto-reject events, a persistent in-app notification inbox, granular user preferences, and WhatsApp deep link routing — all with consistent auth-aware navigation behaviour.
Proposed Solution
Push Notification Events
⚠️ 
ADDITION:
 Four push notification events are supported (previously only two were documented):
Event
Title
Body
Action button
New Order Received
New Order Received
#{order_id} · ₹{amount} · {channel_name}
Process Order
Order Cancelled
Order Cancelled
#{order_id} · ₹{amount} · {channel_name}
None (informational only)
Order Auto-Reject Warning
Order Auto-Reject Warning
#{order_id} will be auto-rejected in {time_remaining}
Process Order
Order Auto-Rejected
Order Auto-Rejected
#{order_id} was auto-rejected
None (informational only)
Action button behaviour:
New Order Received: a "Process Order" action button must appear in the OS notification shade and on the lock screen — tapping it navigates directly to the Order Processing screen for that order
Order Auto-Reject Warning: a "Process Order" action button must appear in the OS notification shade and on the lock screen — tapping it navigates directly to the Order Processing screen for that order
Order Cancelled: informational only — no action button
Order Auto-Rejected: informational only — no action button
Tap behaviour (notification body tap):
Event
App state
Result
New Order Received
Any
Opens Order Processing screen for that order
Order Cancelled
Any
Opens Order Processing screen for that order (read-only view)
Order Auto-Reject Warning
Any
Opens Order Processing screen for that order
Order Auto-Rejected
Any
Opens Order Processing screen for that order (read-only view)
Push Notification Delivery
Delivered only to users subscribed to the relevant event type via in-app preferences
Delivered in all app states: foreground, background, and device locked
Each notification is delivered individually — no grouping or stacking
Foreground behaviour:
 When the app is in the foreground, no banner or toast is shown. The inbox updates silently and the unread count badge increments on the bell icon.
Priority:
Android: FCM 
priority: high
 for immediate delivery and heads-up banner in background/locked states
iOS: APNs 
apns-priority: 10
 for immediate delivery
During mute window on Android: FCM 
priority: normal
 — silent delivery, no heads-up banner
Token Management
FCM token (Android) and APNs token (iOS) registered and linked to the user's account on login
Tokens deregistered from the user's account on logout — ensures a logged-out user does not continue receiving notifications on shared devices
Tokens refreshed automatically by the app and updated in the backend when rotated
In-App Notification Inbox
Accessible from bell icon in the top bar and from the Notifications item in the navigation drawer
Bell icon displays unread count badge; shows "99+" when count exceeds 99
Each notification entry: event type, order ID, amount, channel
Unread notifications visually distinguished from read (coloured dot: green for new order, red for cancellation/auto-reject)
Timestamps: relative within 24 hours (e.g. "2 min ago"); absolute for older (e.g. "Yesterday 14:22")
Viewing a notification marks it as read and removes the dot indicator
Mark All Read
 button clears all unread states
Tapping any entry navigates to the relevant Order Processing screen
Back from Order Processing (arrived via notification) → Notification Inbox
Inbox is read-only in v1 — no delete, archive, or bulk actions
Notification Preferences
All toggles default to OFF for new users
 — explicit opt-in required
⚠️ 
ADDITION:
 Four per-event-type toggles (previously only two were documented):
New Orders
Cancellations
Order Auto-Reject Warning
Order Auto-Rejected
Per-channel filter:
 users can receive notifications only for selected channels (e.g. Shopify AM, not Amazon IN)
Preferences saved per user account (not per device) — carry over on new device login
Auto-save on toggle — no explicit Save button
If OS-level notification permission is denied: inline prompt shown with a direct link to device notification settings
Mute Window
User configures a single daily mute window with start and end time pickers
Overnight mute supported:
 end time earlier than start time spans midnight (e.g. 10 PM – 7 AM)
During mute window: notifications delivered and logged in inbox, but no sound or heads-up banner
Mute applies to all notification types, independent of event type toggles
Saved per user account; carries over on new device login
WhatsApp Deep Link Integration
Order URLs in WhatsApp messages open the app via deep link (App Links on Android / Universal Links on iOS)
App not installed → URL falls back to web URL
User not logged in when tapping deep link → routed to Login screen; after successful login → automatically navigated to the relevant Order Processing screen
Navigation
Push notification tap (OS tray) → auth-aware routing → Order Processing
Notification Inbox: entry from bell icon / Notifications drawer item; tap entry → Order Processing; back → Inbox
Notification Preferences: entry from App Settings; auto-save; back → previous screen
WhatsApp order URL tap → (app installed) auth-aware routing → Order Processing; (app not installed) → web URL fallback
Back from Order Processing (arrived via notification or deep link) → Notification Inbox
Acceptance Criteria
Push Notification Delivery
When a new order is received, a push notification must be delivered with title "New Order Received" and body 
#{order_id} · ₹{amount} · {channel_name}
When an order is cancelled, a push notification must be delivered with title "Order Cancelled" and body 
#{order_id} · ₹{amount} · {channel_name}
When an order is at risk of auto-rejection, a push notification must be delivered with title "Order Auto-Reject Warning" and body 
#{order_id} will be auto-rejected in {time_remaining}
When an order has been auto-rejected, a push notification must be delivered with title "Order Auto-Rejected" and body 
#{order_id} was auto-rejected
A "Process Order" action button must appear in the OS notification shade for New Order Received and Order Auto-Reject Warning events
No action button must appear for Order Cancelled and Order Auto-Rejected events
Push notifications must only be delivered to users who have opted in to the relevant event type
Push notifications must be delivered in all app states: foreground, background, and device locked
Each notification must be delivered individually — no grouping or stacking
When the app is in the foreground, no banner or toast must be shown; the inbox must update silently and the unread badge must increment
On Android, New Order Received, Order Cancelled, Order Auto-Reject Warning, and Order Auto-Rejected must map to FCM priority: high
On iOS, all four event types must map to APNs apns-priority: 10
During an active mute window, notifications must be delivered silently on Android using FCM priority: normal
All push notifications must be logged in the in-app Notification Centre regardless of app state
Tapping a push notification must navigate the user to the Order Processing screen for that order
Tapping New Order Received or Order Auto-Reject Warning notifications via the action button must navigate to Order Processing
Tapping Order Cancelled or Order Auto-Rejected notifications must navigate to Order Processing in a read-only view
Token Management
On login, the FCM token (Android) or APNs token (iOS) must be registered and linked to the user's account
On logout, the device token must be deregistered from the user's account
After logout, the user must not receive push notifications on that device
When the device token is rotated, the app must automatically refresh and update it in the backend
In-App Notification Inbox
The inbox must be accessible from the bell icon and the Notifications drawer item
The bell icon must display an unread count badge; when unread count exceeds 99, the badge must show "99+"
Each notification entry must display: event type, order ID, amount, and channel
Unread notifications must be visually distinguished with a coloured dot — green for new order, red for cancellation and auto-reject events
Timestamps must display as relative time (e.g. "2 min ago") for notifications within the last 24 hours
Timestamps must switch to absolute time (e.g. "Yesterday 14:22") for notifications older than 24 hours
When a notification is viewed, it must be marked as read and the dot indicator must be removed
When the user taps "Mark All Read", all notifications must be marked as read and all dot indicators cleared
When the user taps a notification entry, they must be navigated to the relevant Order Processing screen
The inbox must be read-only in v1 — no delete, archive, or bulk actions
Back from Order Processing (arrived via notification) must return the user to the Notification Inbox
Notification Preferences
All notification toggles (New Orders, Cancellations, Order Auto-Reject Warning, Order Auto-Rejected) must be OFF by default for new users
Users must be able to toggle subscriptions independently for each of the four event types
Users must be able to filter notifications per channel (e.g. receive for Shopify AM but not Amazon IN)
Preferences must be saved per user account and carry over when the user logs in on a new device
Preferences must auto-save on toggle — no explicit Save button
When OS-level notification permission is denied, an inline prompt must be shown with a direct link to device notification settings
Mute Window
Users must be able to set a single daily mute window via a start time and end time picker
When the end time is earlier than the start time, the mute window must be treated as overnight (e.g. 10 PM – 7 AM spans midnight)
During the mute window, notifications must be delivered to the device and logged in the Notification Centre but with no sound or heads-up banner
The mute setting must apply to all notification types when active, independent of individual event type toggles
The mute preference must be saved per user account and carry over on new device login
WhatsApp Deep Link Routing
When the user taps an order URL in WhatsApp and the app is installed, the app must open via deep link (App Links on Android, Universal Links on iOS)
When the user taps an order URL in WhatsApp and the app is not installed, the URL must fall back to the web URL
When the user taps a deep link and is not logged in, they must be routed to the login screen; after successful login, they must be automatically navigated to the relevant Order Detail screen
Navigation & Global
Tapping a push notification from the OS tray must use auth-aware routing to navigate to Order Processing
The Notification Inbox must be accessible from the bell icon and the Notifications drawer item
Tapping a notification entry must navigate to Order Processing
Tapping Back from the inbox must return the user to the previous screen
Notification Preferences must be accessible from App Settings; auto-save on toggle; Back returns to previous screen
Tapping Back from Order Processing (when arrived via notification or deep link) must return the user to the Notification Inbox


### BTA-16464: BT App: Non-Functional Requirements

**Type:** Story · **Status:** Open · **Priority:** Medium  
**Reporter:** Lorraine Pinto  
**Created:** 2026-04-28 · **Updated:** 2026-05-20  
**Jira:** https://ginesysone.atlassian.net/browse/BTA-16464

Background
Non-functional requirements define the quality, performance, and environmental standards the app must meet across its entirety. These are hard constraints that apply to every feature and module, not suggestions. They must be considered during architecture, development, and QA — not retrofitted after the fact.
Objective
Define and enforce the platform compatibility, performance, connectivity, security, accessibility, and operational standards the Browntape Mobile App must meet at launch.
Requirements
7.1 Device & Screen Compatibility
Platforms:
 Android 10+ and iOS 15+
Screen sizes:
 Smartphones from ~360dp width upwards
Tablets:
 Layouts must adapt gracefully to 7–11" screens — content must not overflow, clip, or leave large dead zones on tablet viewports
Orientation:
 Portrait only
Font scaling:
 The app must remain fully usable at up to 
130% system font scale
. Layouts must not break, clip, or overflow at this setting.
7.2 Performance & App Size
Install size:
 Target under 
30 MB
 for the initial download
RAM usage:
 Must function acceptably on devices with 
2 GB RAM
; heavy operations must not cause frame drops or crashes on low-memory devices
Cold start:
 Must reach an interactive state within 
3 seconds
 on a mid-range device under normal network conditions. No heavy assets or expensive operations on the main thread at startup.
Animation performance:
 Target 
60fps
. If a device cannot sustain this, animations should degrade gracefully rather than stutter.
7.3 Network & Connectivity
No internet — full-screen takeover:
 When connectivity is lost entirely, the app must display a full-screen offline state. This must not be a subtle banner or small inline indicator — the user must be clearly informed before attempting any action that would fail silently. A retry mechanism must be available once connectivity is restored.
Minimum viable connection:
 The app must be functional on a 
3G connection (~1–2 Mbps)
. Core workflows must not stall under these conditions.
Offline behaviour:
 The app is not offline-first. Transactional actions must not be queued or submitted silently when offline — the user must be informed and the action must not proceed.
Timeout handling:
 API calls must have a defined timeout threshold. On timeout, the user must see an explicit error with a retry option — not an indefinite spinner.
Image and asset loading:
 Lazy-loaded and compressed. List rendering must not be blocked on image fetch completion.
7.4 Camera & Media Permissions
Contextual request:
 Camera permission must be requested 
only when the user first attempts an action that requires it
. Do not request on app launch or login.
Permission denied:
 The relevant feature must show a clear, non-blocking message with a direct link to device app permission settings. The rest of the app remains fully functional.
Camera initialisation:
 The camera preview should initialise within 
1–2 seconds
 of the scan screen opening. A loading indicator is acceptable on slower devices.
Storage permissions:
 Media captured during QC is uploaded directly and must not require writing to the device's photo library. Avoid requesting storage/media library permissions unless explicitly needed.
7.5 Security
Secure storage:
 Session tokens and persisted credentials must be stored in OS-level secure storage (Android Keystore / iOS Keychain). They must never be stored in shared preferences, local files, or unencrypted databases.
Transport security:
 All API communication must be over HTTPS.
7.6 Accessibility
Touch targets:
 All interactive elements must have a minimum touch target of 
44×44dp
Colour contrast:
 Text and meaningful UI elements must meet 
WCAG AA
 contrast ratios (4.5:1 for body text, 3:1 for large text and UI components). Colour must not be the sole means of communicating state — always pair with a label, icon, or shape.
Screen reader support:
 Core workflows must be navigable via 
TalkBack
 (Android) and 
VoiceOver
 (iOS). Interactive elements must have descriptive accessibility labels.
Error messages:
 All error states must be communicated in text — not through colour or icon alone.
7.7 Crash & Error Monitoring
The app must integrate with a crash reporting tool (e.g. Firebase Crashlytics or equivalent)
Critical user flows (login, order acceptance, return creation) must have error boundary handling — a crash in one section must not bring down the entire app
All API errors should be logged with sufficient context (endpoint, status code, timestamp) without exposing PII in logs
7.8 App Updates & Versioning
Forced updates:
 When a user opens an outdated version, a 
non-dismissible modal
 must prompt them to update via the app store. The user cannot proceed into the app until they update.
Recommended updates:
 Optional update prompts can be used for non-critical upgrades
Version visibility:
 App version and build number must be visible in Settings for support and debugging purposes
Acceptance Criteria
Device & Screen Compatibility
The app must be functional on Android 10+ and iOS 15+
The app must be usable on screen widths from ~360dp upwards
On tablet screens (7–11"), layouts must adapt — content must not overflow, clip, or leave large dead zones
The app must remain fully usable at 130% system font scale — no layout breakage, clipping, or overflow
The app must support portrait orientation only
Performance
The initial download size must target under 30 MB
The app must function acceptably on devices with 2 GB RAM without frame drops or crashes during normal use
The app must reach an interactive state within 3 seconds of cold start on a mid-range device under normal network conditions
No heavy assets or expensive operations must run on the main thread at startup
Animations must target 60fps; if a device cannot sustain this, animations must degrade gracefully rather than stutter
Network & Connectivity
When connectivity is lost entirely, a full-screen offline state must be displayed — not a subtle banner
The full-screen offline state must include a retry mechanism
Core workflows must be functional on a 3G connection (~1–2 Mbps)
Transactional actions must not be queued or submitted silently when offline — the user must be informed and the action must not proceed
All API calls must have a defined timeout threshold; on timeout the user must see an explicit error with a retry option, not an indefinite spinner
List rendering must not be blocked on image fetch completion
Camera & Media
Camera permission must be requested only when the user first attempts a camera-requiring action — not at app launch or login
When camera permission is denied, the relevant feature must show a clear message with a direct link to device app permission settings; the rest of the app must remain functional
The camera preview must initialise within 1–2 seconds of the scan screen opening
Media captured during QC must be uploaded directly and must not require writing to the device photo library
Storage/media library permissions must not be requested unless explicitly required
Security
Session tokens and persisted credentials must be stored in OS-level secure storage (Android Keystore / iOS Keychain)
Session tokens must never be stored in shared preferences, local files, or unencrypted databases
All API communication must be over HTTPS
Accessibility
All interactive elements must have a minimum touch target of 44×44dp
Text and meaningful UI elements must meet WCAG AA contrast ratios: 4.5:1 for body text, 3:1 for large text and UI components
Colour must not be the sole means of communicating state — always paired with a label, icon, or shape
Core workflows must be navigable via TalkBack (Android) and VoiceOver (iOS)
All interactive elements must have descriptive accessibility labels
All error states must be communicated in text, not through colour or icon alone
Crash & Error Monitoring
The app must integrate with a crash reporting tool (e.g. Firebase Crashlytics or equivalent)
A crash in one section of the app (e.g. login, order acceptance, return creation) must not bring down the entire app — error boundaries must be in place for critical flows
API errors must be logged with endpoint, status code, and timestamp without exposing PII
Updates & Versioning
When a user opens an outdated app version, a non-dismissible modal must prompt them to update via the app store — the user must not be able to proceed without updating
App version and build number must be visible in the Settings screen

# Changelog — Phase 2: Architecture Repair 🪐

All architectural adjustments and layout configurations implemented during Phase 2 are documented below.

## 📁 Files Created
- `/flutter_closetos/lib/main.dart` — App entry point containing initialization logic, the global ProviderScope, the dark neon material theme, and the GoRouter loader.
- `/flutter_closetos/lib/router.dart` — Clean-architecture session-aware router leveraging GoRouter. Automatically redirects users based on active Firebase Auth sessions.
- `/flutter_closetos/lib/screens/app_shell.dart` — Custom glassmorphic, floating bottom navigation app shell. Uses `StatefulNavigationShell` for smooth multi-branch sub-state retention.
- `/flutter_closetos/lib/screens/splash_screen.dart` — Elegant initial loader shown during authentication status checks.
- `/flutter_closetos/lib/screens/onboarding_screen.dart` — Fluid intro page guiding users to log in.
- `/flutter_closetos/lib/screens/home_screen.dart` — Stub for the main dashboard.
- `/flutter_closetos/lib/screens/camera_screen.dart` — Stub for the computer vision camera scanner.
- `/flutter_closetos/lib/screens/wardrobe_screen.dart` — Stub for the digital wardrobe explorer.
- `/flutter_closetos/lib/screens/stylist_screen.dart` — Stub for the AI Stylist conversation screen.
- `/flutter_closetos/lib/screens/packing_screen.dart` — Stub for the luggage/packing planner.
- `/flutter_closetos/lib/screens/profile_screen.dart` — Stub for the user profile, accessible from the top header of main tabs.

## 📝 Files Modified
- `/flutter_closetos/pubspec.yaml` — Integrated the `go_router` dependency (`^13.2.0`) to handle stateful shell layouts and deep routing.

## 🏗️ Architecture Decisions
1. **Separation of Concerns via Repository Pattern & Riverpod**: No UI screen fetches Firestore documents or calls Firebase Auth directly. All actions pass through the respective StateNotifierProviders to repositories and services.
2. **Robust, Session-Aware Redirects**: GoRouter watches the native `authStateChanges` stream. While initializing, users remain on the `/splash` screen. If unauthenticated, they are cleanly locked out and redirected to `/onboarding` or `/login`. If logged in, they are immediately navigated to `/home` with zero flicker.
3. **Fail-Safe Startup Core**: Firebase initialization inside `main.dart` is wrapped in a robust try-catch handler, allowing development simulators and physical devices without matching Google configuration keys to load the UI gracefully without hard-crashing.
4. **ExtendBody App Layout**: The `extendBody` property is enabled on the main `AppShell` scaffold. This lets scrollable widgets slide smoothly behind the translucent, glassmorphic bottom navigation bar with real-time blur (`BackdropFilter`), elevating the tactile aesthetic.

## 📋 Remaining Tasks
- **Phase 3: Screen Implementations** — Expand each of the newly created stub screens with high-fidelity, interactive, and responsive UI.
- **Phase 4: Camera Scanner** — Implement local image compression, camera controls, and the Gemini Pro metadata parser.
- **Phase 5: Wardrobe Stream** — Connect the wardrobe screen to the Firestore stream provider with filtering, favorites, and tag queries.
- **Phase 6: AI Stylist Chat** — Build the ChatGPT-like styling assistant with streaming responses and weather integration.
- **Phase 7: Packing Planner** — Connect destination weather with clothes categorization to yield optimized luggage checklists.

## ⚠️ Known Risks & Mitigations
- *Risk*: A missing or unconfigured Firebase project can crash secondary Firestore streams during runtime.
  *Mitigation*: We will write fallback simulated local repository state toggles in the repositories so that if Firestore calls fail or timeout, the app switches to an offline-first demo mode, ensuring a flawless hackathon presentation.

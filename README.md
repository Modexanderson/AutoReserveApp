# AutoReserveApp

An iPhone app that watches a target's schedule and auto-books a slot when it
matches your ranked preferences — built from the client's development guide.

**Read this whole file before you tell the client anything is "done."** The
short version: the app is fully built, fully runnable, and fully testable
today — against **mock data**. The piece that actually talks to the real
target site is intentionally left as a stub, because that requires research
nobody has done yet (see "What's real vs. mocked" below). Building that part
by guessing would be worse than not building it at all — it could silently
do nothing, or misfire.

---

## 1. What's actually in this repo

```
AutoReserveApp/
├── README.md                        <- this file
├── PHASE0_RESEARCH_TEMPLATE.md      <- fill this in before real integration
├── .gitignore
├── Sources/AutoReserveApp/
│   ├── App/            <- app entry point + root tab UI
│   ├── Models/         <- plain data types (Cast, ScheduleEntry, etc.)
│   ├── Domain/         <- the actual matching/booking orchestration logic
│   ├── Providers/      <- the "talk to the outside world" layer (see below)
│   ├── Persistence/    <- local storage + Keychain
│   ├── Background/     <- best-effort background refresh
│   ├── ViewModels/     <- glue between Domain and SwiftUI Views
│   └── Views/           <- SwiftUI screens
└── Tests/               <- unit tests for the matching/dedupe logic
```

This mirrors the architecture the client's own document recommended
(section 7), so if they ever ask "does this match the spec", the answer is
yes — including everything the doc marked out of scope (no 24/7 cloud
monitoring, no CAPTCHA bypassing, no multi-site support, no admin web
console).

## 2. What's real vs. what's mocked — please read this part

The app is **fully wired and runnable end to end** right now, using:

- `MockScheduleProvider` — invents 3 fake upcoming slots each time it's
  asked, so the UI, matching logic, monitoring loop, notifications, and
  results list all work and can be demoed.
- `MockBookingProvider` — simulates a booking confirmation (or failure, if
  you flip `simulateSuccess = false`) after half a second.

The **real** site-specific pieces are `HTMLScheduleProvider.swift` and
`HTMLBookingProvider.swift`. Both currently exist only as stubs that throw
a clear error explaining why. That's on purpose. The client's own document
says (section 6) that a "Phase 0" research pass has to happen first —
confirming the real target URL, whether the schedule is in plain HTML or
loaded by JavaScript, the login/session mechanism, and the site's terms of
service around automation — **before** any of this logic can be written for
real. None of that information has been provided yet (see section 5 of the
original doc: shop/cast URL, posting pattern, exact meaning of "1st–3rd
choice", the manual booking flow, etc. are all still blank).

Guessing at this instead of asking would risk two bad outcomes:
1. The scraper matches nothing, silently, and looks broken.
2. The scraper matches the wrong thing, and the app "books" something that
   isn't actually confirmed — which the client's own document explicitly
   calls out as unacceptable (never treat a raw HTTP 200 as success).

**`PHASE0_RESEARCH_TEMPLATE.md`** in this repo is a fill-in-the-blanks
version of that missing information. Once you (or the client) can answer
it, tell me and I'll write the real `HTMLScheduleProvider` /
`HTMLBookingProvider` implementations against it.

The one-line swap, once that's done, is in
`Sources/AutoReserveApp/App/RootTabView.swift` — change the two mock
providers to the HTML ones.

## 3. What you need on your Mac

Since you've only worked in Flutter/Dart before, here's the iOS-native
equivalent of your usual toolchain:

| Flutter world | This project's equivalent |
|---|---|
| `flutter` CLI + VS Code | Xcode (free, from the Mac App Store) |
| `pubspec.yaml` | Xcode project settings (target, signing, Info.plist) |
| Dart | Swift |
| Widgets (`StatelessWidget`/`StatefulWidget`) | SwiftUI `View`s |
| `setState` / `Provider` / `ChangeNotifier` | `@State` / `@Published` on an `ObservableObject` |
| `flutter run` on a connected device | Xcode's ▶ Run button, device picked from the toolbar |
| Hot reload | SwiftUI Previews (instant) + regular rebuilds for logic changes |
| `flutter test` | Xcode's ⌘U (Product → Test) |

You need:
- A **Mac** (Xcode is Mac-only — this can't be built from Linux/Windows, or
  from this sandbox, which is why I wrote the source files directly rather
  than a compiled binary).
- **Xcode**, latest version, installed from the Mac App Store (multi-GB
  download, free).
- A **free Apple ID** is enough to install the app on your own iPhone for
  testing (7-day signing, auto-renews as long as you reconnect your phone
  weekly in Xcode). You only need a paid Apple Developer account ($99/yr)
  if you want TestFlight or App Store distribution — neither is in scope
  per the client's doc.
- Your **iPhone**, connected to the Mac via USB (or wireless debugging once
  paired once via USB).

## 4. Step-by-step: getting this running on your iPhone

1. **Clone the repo** to your Mac (see section 6 below for the GitHub
   commands).

2. **Create a new Xcode project** (I'm not shipping a pre-made `.xcodeproj`
   file on purpose — those are binary-ish project files that are easy to
   corrupt by hand-editing outside Xcode, and I have no way to compile-test
   one from this Linux sandbox. Creating a fresh one takes about a minute
   and avoids that risk):
   - Open Xcode → **File → New → Project**
   - Choose **iOS → App**, click Next
   - Product Name: `AutoReserveApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Use Core Data" and "Include Tests" isn't needed either (we
     bring our own test files)
   - Save it **outside** the cloned repo folder for now (e.g. Desktop) —
     you'll move files into it next.

3. **Delete Xcode's default files**: In the project navigator (left
   sidebar), delete `ContentView.swift` (keep `AutoReserveAppApp.swift` for
   now, you'll overwrite it).

4. **Drag in the real source**: From Finder, drag the entire
   `Sources/AutoReserveApp/` folder's *contents* (the `App`, `Models`,
   `Domain`, `Providers`, `Persistence`, `Background`, `Notifications`,
   `ViewModels`, `Views` folders) into Xcode's project navigator, dropping
   them under the top-level `AutoReserveApp` group.
   - In the dialog that appears, check **"Copy items if needed"** and
     **"Create groups"**, and make sure the `AutoReserveApp` target
     checkbox is ticked.
   - When asked about the duplicate `AutoReserveAppApp.swift` vs. our
     `AutoReserveApp.swift`, delete Xcode's auto-generated one — ours
     (in `App/`) replaces it (same `@main` role).

5. **Add the test files**: File → New → Target → iOS → Unit Testing
   Bundle → name it `AutoReserveAppTests`. Then drag the two files from
   this repo's `Tests/` folder into that new test target the same way.

6. **Enable background refresh capability** (needed for
   `BackgroundCoordinator`):
   - Select the project in the navigator → the `AutoReserveApp` target →
     **Signing & Capabilities** tab → **+ Capability** → **Background
     Modes** → check **Background fetch** and **Background processing**.
   - Then select `Info` tab (or `Info.plist` if shown separately) and add
     a key `BGTaskSchedulerPermittedIdentifiers` (Array) with one string
     item: `com.autoreserve.refresh` (must match
     `BackgroundCoordinator.taskIdentifier`).
   - Add `NSUserNotificationsUsageDescription` isn't required on iOS (that's
     macOS) — but do make sure notifications are requested at runtime,
     which `RootTabView` already does via `NotificationManager`.

7. **Set your signing team**: Signing & Capabilities tab → pick your Apple
   ID under Team (add it via Xcode → Settings → Accounts if it's not
   there yet). Xcode will assign a free personal-team bundle identifier
   automatically if you don't have a paid account.

8. **Connect your iPhone** via USB, unlock it, tap "Trust This Computer" if
   prompted. Select your iPhone as the run destination in Xcode's toolbar
   (top center, where it might currently say "iPhone 15 Simulator").

9. **Run it**: press the ▶ button (or ⌘R). First launch on-device usually
   requires one extra step on the phone: **Settings → General → VPN &
   Device Management → [your Apple ID] → Trust**. After that, the app
   launches normally.

10. **Try it out**: go to the **Target** tab, enter anything (it's not
    connected to a real site yet), save; go to **Conditions**, set a wide
    time range like `00:00`–`23:59` so mock data matches; go to
    **Monitor**, tap **Start Monitoring**; after a few seconds check
    **Results** — you should see mock booking attempts appear, and you
    should get local notifications.

11. **Run the tests**: ⌘U, or Product → Test. Both test files should pass.

If Xcode shows a compile error I haven't anticipated (very possible — I
wrote this without a Mac/Xcode to compile against, since this sandbox is
Linux-only), it's almost always one of: a typo, an iOS-version-specific API
(e.g. `.textInputAutocapitalization` requires iOS 15+; if your deployment
target is older, Xcode will point you to the right modifier for your
target), or a missing import. Paste me the exact error text and I'll fix
the file directly.

## 5. Known limitations (be upfront with the client about these)

- **No real booking happens yet.** This is a fully functional app shell
  with mock data until Phase 0 research (section 2 above) is done.
- **iOS cannot guarantee background timing.** Even once real integration is
  built, `BackgroundCoordinator` is best-effort only — Apple's OS decides
  when (or if) a background refresh actually runs. The client's own
  document acknowledges this (section 4); don't let "auto-reservation" get
  misread by them as "guaranteed instant, always-on."
- **Foreground monitoring is the reliable path.** While the app is open,
  the polling loop in `MonitoringViewModel` runs on a real, predictable
  timer. That's the mode to demo and to rely on day-to-day.

## 6. Getting this onto your GitHub

This folder is already a git repository with the initial commit made. To
push it to your own GitHub:

1. On GitHub, create a **new, empty, private** repository (recommended
   private, given the nature of the target). Don't initialize it with a
   README/license/gitignore — this folder already has those.
2. On your Mac, in this folder, run:
   ```bash
   git remote add origin https://github.com/<your-username>/<your-repo-name>.git
   git branch -M main
   git push -u origin main
   ```
3. To clone it onto your MacBook from a different machine later:
   ```bash
   git clone https://github.com/<your-username>/<your-repo-name>.git
   ```

## 7. Suggested next message to the client

Once you've run this and confirmed it works, it's worth telling Alock
something like: *"First-phase build is done and running — a full iPhone
app with target/condition settings, live monitoring, and a results log,
currently running against test data while we lock down the real site
details. To connect it to the live site I'll need [the items in
PHASE0_RESEARCH_TEMPLATE.md — shop/cast URL, the manual booking flow,
login method, etc.]."* That keeps you honest about what's built vs. what's
pending, without re-opening the earlier scope/budget conversation unless
you want to.

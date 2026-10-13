# Frugality Pug

Native SwiftUI iPhone personal-finance app (budget, retirement, net worth, real estate, take-home pay, loan amortization).
On-device only: no accounts, no cloud, no analytics, no ads. Owner: Chad.
Chad has a PC and an iPhone, no Mac. Builds run on Codemagic and ship through TestFlight.
The Linux container where Claude works has no Swift toolchain, so tests and builds run in Codemagic CI, not locally.

## Working rules (read first)
1. Fix only the problem asked. No drive-by refactors, renames, reformatting, or "while I'm here" edits. If you spot something else, mention it in one line and leave it alone.
2. Write real, general solutions. Never code that only works for one example, state, filing status, year, or input. Zero, negative, empty, and maximum inputs must behave correctly.
3. Money math lives only in `Packages/FrugalityCore`, never in views. Any change to calc logic adds or updates a unit test.
4. Tax rates, brackets, and limits live in data files under `Resources/tax/<year>/`, never in Swift code.
5. Never commit secrets. See `CREDENTIALS.md`.
6. Priority Pusher (`chadhamiltonlds/priority-pusher-site`) and Platypug (`platypuggames/platypug`) are read-only. Look and copy, never change, push to, or reconfigure them.
7. Commit to `main` (Chad builds from `main` and doesn't manage branches), one concern per commit. Do not rewrite or reformat files you were not asked to touch.

## Chad's preferences
- Terse, numbers first, practical, action-oriented. Precise, not broad or hedged.
- Direct and honest. Do not fold under pushback unless actually wrong.
- Setup and how-to steps go inline in the chat, not in step-card widgets.
- Ask only when a wrong guess is costly. Otherwise decide, and state the decision in one line.

## Layout
```
CLAUDE.md              this file (keep under ~150 lines)
CREDENTIALS.md         which credentials exist and where they live (no secret values)
project.yml            XcodeGen spec; generates the .xcodeproj on CI (never hand-edit or commit the .xcodeproj)
codemagic.yaml         CI: `ci-check` (every push: core tests + simulator build) and `testflight` (manual upload)
Config/                holds the generated Info.plist (gitignored)
App/                   iOS target (SwiftUI)
  FrugalityPugApp.swift  app entry
  Home/                home grid, reorderable tiles, and the Feature list (add new calculators here)
  Theme/               colors, fonts, card styles (single source of look and feel)
  Persistence/         the only place that reads/writes saved data; versioned, with migrations
  Shared/              views/helpers used by 2+ features
  Features/<Name>/     one folder per feature: views + view models only, no money math
Packages/FrugalityCore/  Swift package: all calculation logic, no UI/persistence imports
  Sources/FrugalityCore/<Name>/   pure functions and Codable structs per feature
  Sources/FrugalityCore/Shared/   money/rate helpers shared by features
  Sources/FrugalityCore/Resources/tax/<year>/   federal and per-state tax data (JSON)
  Tests/FrugalityCoreTests/       unit tests, mirrors Sources layout
Assets/                icon generator (make_icon.py) and its source art (source/); the icon PNG lives in App/Assets.xcassets
docs/                  features/<name>.md per calculator, features/shared.md, tax-data.md
```

## Features
Each calculator lives in exactly two folders, `App/Features/<Folder>/` and `Packages/FrugalityCore/Sources/FrugalityCore/<Folder>/`, plus its tests and one doc.
**To change one calculator, read only its doc, its two folders, and its test file. Read `docs/features/shared.md` instead of the shared source files. Don't read other features.**

| Folder | Doc | Status |
|---|---|---|
| TakeHome | `docs/features/take-home.md` | built |
| Retirement | `docs/features/retirement.md` | built |
| NetWorth | `docs/features/net-worth.md` | built |
| RentVsBuy | `docs/features/rent-vs-buy.md` | built |
| RealEstateSnowball | `docs/features/real-estate-snowball.md` | built |
| Budget | `docs/features/budget.md` | built |
| Amortization | `docs/features/amortization.md` | built |

Home screen: `App/Home/` (tile list in `Feature.swift`; tiles are fixed-size and reorder by press-and-hold; order saved under `StoreKey.homeOrder`).
When you change a calculator's inputs, outputs, or method, update its doc in the same commit.

## Architecture rules (what keeps changes safe)
- `FrugalityCore` never imports SwiftUI or touches storage. Inputs and outputs are plain Codable structs. Pure functions.
- Features do not import each other. Shared code goes in `App/Shared` or `FrugalityCore/Shared`.
- Persisted data: `App/Persistence/JSONStore.swift` (one JSON file per `StoreKey`). Change a saved type's shape only with a version bump (and a migration if old data must survive).
- Tax data: add a new `<year>` folder; never edit a released year in place unless fixing a verified error.
- The `.xcodeproj` is generated from `project.yml`. Add files by dropping them in folders, not by editing project files.

## Domain rules
- Pay frequency: Budget allows monthly or semi-monthly (24 per year) only, never biweekly. TakeHome also offers biweekly (26 per year).
- TakeHome v1: federal income tax, FICA, state income tax for 50 states plus DC, filing status, dependents, pre-tax deductions. No local taxes.
- Currency: use `Decimal`, not `Double`, for money. Round to cents at each tax line, not mid-calculation.
- Tax data details, sources, and known limits: `docs/tax-data.md`.

## Theme (matches Priority Pusher)
Cream `#FFF4E4`, peach `#F9D3A0`, red accent `#E5484D`, muted brown `#8A6F66`, dark brown text `#2B1E1A`.
Warm peach gradient backgrounds, white rounded cards, red/orange/tan chips.
Icon: the fawn pug from Priority Pusher's icon, used from its vector original (`Assets/source/pug-fawn.svg`, copied unchanged from Platypug), peeking over a gold coin engraved with the same pug's head. Built by `Assets/make_icon.py` (needs `pip install cairosvg`). Never redraw or reshape the pug.

## Build and accounts
- GitHub: `chadhamiltonlds/frugality-pug`. Claude's GitHub access follows whichever account Chad's claude.ai GitHub integration is connected to; one account at a time.
- CI: Codemagic (reused from Priority Pusher). Apple developer account: the family account.
- Bundle ID: `com.frugalitypug.app` (registered). App Store Connect Apple ID: 6821125716.

## Token hygiene
- Keep this file short. Put long notes in `docs/` and link them.
- If `/init` is run to regenerate this file, keep the Working rules, Chad's preferences, Layout, and Features sections.

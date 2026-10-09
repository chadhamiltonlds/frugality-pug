# Frugality Pug

Native SwiftUI iPhone personal-finance app (budget, retirement, net worth, real estate, take-home pay).
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
7. Work on a branch, one concern per commit. Do not rewrite or reformat files you were not asked to touch.

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
codemagic.yaml         CI: generate project, run core tests, build, upload to TestFlight
App/                   iOS target (SwiftUI)
  Theme/               colors, fonts, card styles (single source of look and feel)
  Persistence/         the only place that reads/writes saved data; versioned, with migrations
  Shared/              views/helpers used by 2+ features
  Features/<Name>/     one folder per feature: views + view models only, no money math
Packages/FrugalityCore/  Swift package: all calculation logic, no UI/persistence imports
  Sources/FrugalityCore/<Name>/   pure functions and Codable structs per feature
  Sources/FrugalityCore/Shared/   money/rate helpers shared by features
  Sources/FrugalityCore/Resources/tax/<year>/   federal and per-state tax data (JSON)
  Tests/FrugalityCoreTests/       unit tests, mirrors Sources layout
Assets/                icon source art and image sources
docs/                  long reference notes (link from here, do not paste into this file)
```

## Features (folder name in both `App/Features` and `FrugalityCore`)
| Folder | What it does | Status |
|---|---|---|
| Retirement | Projects savings at retirement from adjustable parameters | planned |
| RentVsBuy | Rent vs buy analysis for homes, built from scratch | planned |
| NetWorth | Debts and assets in, net worth out | planned |
| RealEstateSnowball | How fast one rental can snowball into more properties | planned |
| TakeHome | Net pay from gross, state, dependents, filing status, pre-tax deductions | planned |
| Budget | Line-by-line monthly income and expenses with categories | planned |

Update the Status column when a feature lands.

## Architecture rules (what keeps changes safe)
- `FrugalityCore` never imports SwiftUI or touches storage. Inputs and outputs are plain Codable structs. Pure functions.
- Features do not import each other. Shared code goes in `App/Shared` or `FrugalityCore/Shared`.
- Persisted data: change a saved field only with a version bump and a migration in `App/Persistence`.
- Tax data: add a new `<year>` folder; never edit a released year in place unless fixing a verified error.
- The `.xcodeproj` is generated from `project.yml`. Add files by dropping them in folders, not by editing project files.

## Domain rules
- Pay frequency: monthly or semi-monthly (24 per year) only. No biweekly, ever.
- TakeHome v1: federal income tax, FICA, state income tax for 50 states plus DC, filing status, dependents, pre-tax deductions. No local taxes.
- Currency: use `Decimal`, not `Double`, for money. Round only at display.

## Theme (matches Priority Pusher)
Cream `#FFF4E4`, peach `#F9D3A0`, red accent `#E5484D`, muted brown `#8A6F66`, dark brown text `#2B1E1A`.
Warm peach gradient backgrounds, white rounded cards, red/orange/tan chips.
Icon: the fawn pug head next to a bag of money, on the peach background.

## Build and accounts
- GitHub: `chadhamiltonlds/frugality-pug`. Claude's GitHub access follows whichever account Chad's claude.ai GitHub integration is connected to; one account at a time.
- CI: Codemagic (reused from Priority Pusher). Apple developer account: the family account.
- Bundle ID (proposed, confirm before creating the App Store Connect entry): `com.frugalitypug.app`.

## Token hygiene
- Keep this file short. Put long notes in `docs/` and link them.
- Run `/init` once real code exists (after `FrugalityCore` and the first feature are in) to regenerate and trim this file. Keep the Working rules, Chad's preferences, and Layout sections when it does.

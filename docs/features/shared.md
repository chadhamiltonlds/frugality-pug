# Shared pieces (read this instead of the shared source files)

## Core (`Packages/FrugalityCore/Sources/FrugalityCore/Shared/`)
- `Decimal.roundedToCents()`, `Decimal.rounded(toPlaces:mode:)` (Decimal+Rounding.swift)
- `Decimal.clamped(to:)`, `Decimal.asSafeRate` (>= -99%), `Int.clamped(_:_:)` (Clamping.swift)
- `Mortgage.monthlyPayment(principal:annualRate:years:)` (term clamped to 1...50 years), `Mortgage.step(balance:annualRate:payment:)` (Mortgage.swift). Used by RentVsBuy, RealEstateSnowball, Amortization, and RentalAnalysis.
- `PayFrequency` (monthly / semiMonthly / biweekly) used by TakeHome only. Budget has its own `BudgetPaySchedule` (no biweekly).
- `FilingStatus`, `TaxBracket` + `progressiveTax`, `KeyedDecodingContainer.decodeDecimal` (TakeHome tax data).
- Test helpers (`Tests/FrugalityCoreTests/TestSupport.swift`): `dec("1.23")` exact Decimal, `assertClose(a, b, tolerance:)` for long simulations, `Fixtures.data` (tax data).

## App (`App/Shared/`, `App/Theme/`, `App/Persistence/`)
- `CalculatorScreen(title:) { cards }`: background, scrolling stack, inline nav title.
- `SectionCard(title:) { rows }`: titled white card. `ResultRow(label:value:emphasized:valueColor:)`. `HeadlineNumber(caption:value:color:footnote:)`.
- Inputs: `MoneyField(title:value:)` (Decimal dollars), `PercentField(title:value:)` (Decimal fraction; typing 7 = 0.07). Use `Stepper` for ages and years.
- Lists: `AddRowButton(title:action:)`, `DeleteRowButton(action:)`.
- Formatting: `Decimal.asCurrency` ($1,234.50), `.asWholeCurrency` ($1,235), `.asPercent` (from a fraction), `.doubleValue` (charts only).
- Charts: `ChartPoint(x:y:series:)`, `ChartColors.series1` (red) / `.series2` (blue), validated for color-blind separation. `compactDollars(_:)` for axis labels. Two-series charts get a legend; every chart has a year-by-year table under it.
- Theme: `Theme.cream/peach/accent/muted/ink/positive`, `.card()`, `ThemedBackground()`.
- Saving: `JSONStore.load(Type.self, key:)` / `JSONStore.save(value, key:)`; keys and schema versions in `StoreKey`. View models save on every input change.

## Pattern every calculator follows
`<Name>ViewModel` holds `@Published var input` (loaded from `JSONStore`, saved in `didSet`, result recomputed in `didSet`) and `result`. `<Name>View` is a `CalculatorScreen` of input cards, then result, chart, table. All math is in the core calculator.

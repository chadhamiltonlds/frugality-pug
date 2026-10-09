# Tax data (2026)

Files: `Packages/FrugalityCore/Sources/FrugalityCore/Resources/tax/2026/federal.json` and `states.json`.
Load with `TaxYearData.load(year:)`. `validate()` runs on load and rejects unsorted brackets or duplicate states.

## Sources (checked Oct 2026)
- Federal brackets, standard deductions: IRS inflation adjustments for 2026 (Rev. Proc. 2025-32), via CPA Practice Advisor and pennycalc.com.
- Social Security wage base $184,500, 401(k) $24,500, HSA $4,400/$8,750, child tax credit $2,200, additional Medicare thresholds: everwisecu.com 2026 tax tables.
- State brackets, standard deductions, exemptions: Tax Foundation, State Individual Income Tax Rates and Brackets, 2026 (rates as of Jan 1, 2026).

## How to update
- New year: copy the folder to `tax/<year>/`, edit the numbers, set `TaxYearData.latestYear`, add tests. Do not edit a released year except to fix a verified error.
- Numbers are plain JSON numbers. They are read with `decodeDecimal` (Shared/DecimalDecoding.swift) so they stay exact.

## Modeling choices and limits
- Head of household uses single-filer state figures.
- Not modeled: local taxes (NYC, MD counties, etc.), state payroll taxes (CA SDI, NY/NJ/WA programs), AMT, itemized deductions, refundable child credit, income phase-outs of state deductions or credits.
- Where a known state rule is missing, the state is flagged `approximate` with a `note` that the UI shows.
- Federal child credit is non-refundable here and phases out at $50 per $1,000 over $200,000 ($400,000 joint).
- PA and NJ tax 401(k) deferrals; the model reflects this via `taxes401kContributions`.
- Washington taxes capital gains only, so wage income is treated as untaxed.

# Take-Home Pay
Files: `App/Features/TakeHome/`, `FrugalityCore/TakeHome/` (TaxData.swift, TakeHomeCalculator.swift), tax JSON in `Resources/tax/<year>/`, tests `TakeHomeCalculatorTests`, `TaxDataTests`, `ProgressiveTaxTests`. Save key: `.takeHome`.

- Input `TakeHomeInput`: gross annual, `PayFrequency` (monthly, semi-monthly, biweekly), filing status, state code, children under 17, other dependents, pre-tax 401(k), pre-tax Section 125, post-tax deductions (all annual).
- Method: federal brackets after standard deduction, child/dependent credit with phase-out, Social Security (wage base) + Medicare + additional Medicare, state brackets with deductions/exemptions/credits. Rounds each tax line to cents.
- Output `TakeHomeResult`: each tax line, net annual, net per period, effective rate, state approximate flag/note.
- Limits and data sources: `docs/tax-data.md`.

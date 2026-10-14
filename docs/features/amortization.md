# Amortization
Files: `App/Features/Amortization/`, `FrugalityCore/Amortization/AmortizationCalculator.swift`, uses `Mortgage`. Tests `AmortizationCalculatorTests`. Save key: `.amortization`.

- Input `AmortizationInput`: loan amount, annual rate, term years, extra principal per month, "check balance after" years.
- Method: fixed-rate schedule month by month (`Mortgage.step`) with payment + extra; the last payment is capped at the balance. A second run without the extra gives interest saved. Clamps: term 1...50, check year 0...term, negatives to 0.
- Output `AmortizationResult`: scheduled payment, yearly rows (principal, interest, balance, cumulative interest), payoff months, total interest, total paid, interest saved, balance and share paid off at the check year.
- Screen: loan inputs (term stepper 5–40 years in 5-year steps; the view model keeps the check year within the term), "Still owed" card with a year stepper, whole-loan summary, balance chart (check year marked), yearly table (check year bold). Taxes, insurance and PMI not included.

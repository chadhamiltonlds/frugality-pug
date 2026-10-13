# Rental Property
Files: `App/Features/RentalAnalysis/`, `FrugalityCore/RentalAnalysis/RentalAnalysisCalculator.swift`, uses `Mortgage`. Tests `RentalAnalysisCalculatorTests`. Save key: `.rentalAnalysis`.

- Input `RentalAnalysisInput`: price, down %, closing %, upfront repairs, mortgage rate and term; rent, other income, vacancy %; property tax/yr, insurance/yr, HOA/mo, owner-paid utilities/mo, repairs %, capex % and management % of gross income; appreciation; targets (cash flow/mo, cash-on-cash, cap rate, debt coverage, rent/price).
- Method (first year, monthly): gross = rent + other; NOI = gross - vacancy - expenses; cash flow = NOI - mortgage P&I. Cash invested = down + closing + repairs. Cap rate = NOI x 12 / price. Cash-on-cash = yearly cash flow / cash invested. Debt coverage = NOI / payment. Rent/price = rent / price. GRM = price / yearly gross. Break-even occupancy = (expenses + payment) / gross. Total return = (cash flow + 12 months principal paydown + appreciation) / cash invested.
- Checks: each measure vs its target. With no loan, debt coverage passes; with no cash invested, cash-on-cash passes if cash flow is positive.
- Verdict: good = 4+ checks pass and cash flow > 0; weak = cash flow < 0 or at most 1 check passes; else borderline.
- Not modeled: income tax, depreciation, rent growth beyond year 1, selling costs.

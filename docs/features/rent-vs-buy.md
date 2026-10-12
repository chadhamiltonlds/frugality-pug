# Rent vs Buy
Files: `App/Features/RentVsBuy/`, `FrugalityCore/RentVsBuy/RentVsBuyCalculator.swift`, uses `Mortgage`. Tests `RentVsBuyCalculatorTests`. Save key: `.rentVsBuy`.

- Input `RentVsBuyInput`: horizon years; home price, down %, mortgage rate and term, closing %, selling %, property tax %, insurance/yr, HOA/mo, maintenance %, appreciation; rent, rent growth, renter's insurance/yr; investment return.
- Method: monthly. Owner cost = mortgage P&I + (tax + maintenance) on current value + insurance + HOA. Renter cost = rent + renter's insurance. The renter invests the buyer's upfront cash on day one; each month whoever pays less invests the difference at the investment return. Home value and rent step up yearly.
- Output: yearly buyer net worth (value after selling costs - loan + investments) vs renter net worth, break-even year, upfront cash, payment, first-month costs.
- Not modeled: tax effects, PMI, refinancing, growth in insurance/HOA.

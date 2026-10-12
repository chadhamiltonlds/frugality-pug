# Property Snowball
Files: `App/Features/RealEstateSnowball/`, `FrugalityCore/RealEstateSnowball/SnowballCalculator.swift`, uses `Mortgage`. Tests `SnowballCalculatorTests`. Save key: `.snowball`.

- Input `SnowballInput`: years, starting cash, monthly savings, price, down %, closing %, mortgage rate and term, rent, vacancy %, repairs % and management % of rent, taxes+insurance/yr, appreciation, rent growth, reinvest toggle, max properties.
- Method: buy at month 0 if affordable. Each month every property collects rent minus vacancy and pays repairs, management, taxes+insurance/12 and its mortgage; savings (plus cash flow if reinvesting) go to cash, and negative cash flow always comes out of cash. Whenever cash covers down + closing at the current price, buy another (up to the cap). Prices, rents and taxes rise yearly.
- Output: purchases (number, month, price), yearly rows (properties, value, debt, equity, cash, yearly cash flow, net worth), cash needed per property, first-month cash flow per property.
- Not modeled: refinancing or cash-out, income tax, selling.

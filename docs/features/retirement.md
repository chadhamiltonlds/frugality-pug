# Retirement
Files: `App/Features/Retirement/`, `FrugalityCore/Retirement/RetirementCalculator.swift`, tests `RetirementCalculatorTests`. Save key: `.retirement`.

- Input `RetirementInput`: current age, retirement age, current savings, monthly contribution, employer monthly contribution, yearly contribution growth, yearly return, inflation, withdrawal rate.
- Method: month by month, balance grows by return/12, then that month's contribution is added. Contributions rise once a year. Today's dollars = balance / (1 + inflation)^years. Ages clamped 0...120; retirement age below current age gives no projection years.
- Output `RetirementResult`: yearly rows (age, balance, today's dollars, total contributed), final balance both ways, total contributed, growth, yearly/monthly income at the withdrawal rate.
- Screen: inputs, results, two-line chart (future vs today's dollars), yearly table.

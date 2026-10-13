import XCTest
@testable import FrugalityCore

/// $69,900/yr for 35 years gives average indexed monthly earnings of $5,825, the case in SSA's
/// "Benefit Calculation Examples for Workers Retiring in 2026": PIA $2,609.80, $1,826 at 62.
final class SocialSecurityTests: XCTestCase {
    private let data: SocialSecurityData = {
        do { return try SocialSecurityData.load(year: 2026) } catch { fatalError("\(error)") }
    }()
    private let bornAfter1960 = 1996

    private func monthly(_ earnings: Decimal, years: Int = 35, claim: Int, born: Int = 1996) -> SocialSecurityEstimate {
        data.estimate(SocialSecurityInput(isOn: true, annualEarnings: earnings, yearsWorked: years, claimAge: claim), birthYear: born)
    }

    func testMatchesSSAExampleAtFullRetirementAge() {
        let e = monthly(69_900, claim: 67)
        XCTAssertTrue(e.eligible)
        XCTAssertEqual(e.fullRetirementAgeMonths, 804)
        XCTAssertEqual(e.benefitAtFullRetirementAge, dec("2609.8"))
        XCTAssertEqual(e.monthlyBenefit, 2_609)
        XCTAssertEqual(e.annualBenefit, 31_308)
    }

    func testMatchesSSAExampleAtSixtyTwo() {
        let e = monthly(69_900, claim: 62)
        XCTAssertEqual(e.claimAdjustment.rounded(toPlaces: 6, mode: .plain), dec("-0.3"))
        XCTAssertEqual(e.monthlyBenefit, 1_826)
    }

    func testDelayingToSeventyAddsTwentyFourPercent() {
        let e = monthly(69_900, claim: 70)
        XCTAssertEqual(e.claimAdjustment.rounded(toPlaces: 6, mode: .plain), dec("0.24"))
        XCTAssertEqual(e.monthlyBenefit, 3_236)
    }

    func testFewerYearsLowerTheAverage() {
        XCTAssertEqual(monthly(69_900, years: 20, claim: 67).monthlyBenefit, 1_810)   // AIME $3,328 (rounded down)
    }

    func testEarningsAboveWageBaseAreCapped() {
        let e = monthly(300_000, claim: 67)
        XCTAssertEqual(e.benefitAtFullRetirementAge, dec("4369.4"))
        XCTAssertEqual(e.monthlyBenefit, 4_369)
    }

    func testUnderTenYearsIsNotEligible() {
        let e = monthly(69_900, years: 9, claim: 67)
        XCTAssertFalse(e.eligible)
        XCTAssertEqual(e.monthlyBenefit, 0)
    }

    func testEarlierBirthYearHasEarlierFullRetirementAge() {
        let e = monthly(69_900, claim: 66, born: 1957)
        XCTAssertEqual(e.fullRetirementAgeMonths, 798)
        XCTAssertEqual(e.monthlyBenefit, 2_522)
    }

    func testClaimAgeIsClampedToSixtyTwoThroughSeventy() {
        XCTAssertEqual(monthly(69_900, claim: 60).claimAge, 62)
        XCTAssertEqual(monthly(69_900, claim: 60).monthlyBenefit, 1_826)
        XCTAssertEqual(monthly(69_900, claim: 75).claimAge, 70)
    }

    func testNoEarningsIsNotEligible() {
        let e = monthly(0, claim: 67)
        XCTAssertFalse(e.eligible)
        XCTAssertEqual(e.monthlyBenefit, 0)
    }

    func testTotalIncomeAddsBenefitToWithdrawals() {
        let result = RetirementCalculator.project(RetirementInput(currentAge: 70, retirementAge: 65, currentSavings: 300_000))
        XCTAssertEqual(result.monthlyIncomeInTodayDollars, 1_000)
        XCTAssertEqual(RetirementCalculator.totalMonthlyIncome(result, socialSecurity: monthly(69_900, claim: 67)), 3_609)
        XCTAssertEqual(RetirementCalculator.totalMonthlyIncome(result, socialSecurity: nil), 1_000)
    }

    func testInputsSavedBeforeSocialSecurityStillDecode() throws {
        let old = #"{"currentAge":40,"retirementAge":65,"currentSavings":1000,"monthlyContribution":0,"employerMonthlyContribution":0,"contributionGrowthRate":0,"annualReturn":0.07,"inflationRate":0.03,"withdrawalRate":0.04}"#
        let input = try JSONDecoder().decode(RetirementInput.self, from: Data(old.utf8))
        XCTAssertEqual(input.currentAge, 40)
        XCTAssertNil(input.socialSecurity)
    }
}

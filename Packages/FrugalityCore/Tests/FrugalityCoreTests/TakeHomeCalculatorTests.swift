import XCTest
@testable import FrugalityCore

/// Expected values come from an independent reference implementation (Python, Decimal math)
/// reading the same tax data files, and cases A, B, C and D were also checked by hand.
final class TakeHomeCalculatorTests: XCTestCase {
    private func run(_ input: TakeHomeInput) throws -> TakeHomeResult {
        try TakeHomeCalculator.calculate(input, data: Fixtures.data)
    }

    func testSingle100kNoStateTax() throws {
        let r = try run(TakeHomeInput(grossAnnual: 100_000, stateCode: "TX"))
        XCTAssertEqual(r.federalIncomeTax, 13170)
        XCTAssertEqual(r.socialSecurity, 6200)
        XCTAssertEqual(r.medicare, 1450)
        XCTAssertEqual(r.additionalMedicare, 0)
        XCTAssertEqual(r.stateIncomeTax, 0)
        XCTAssertEqual(r.netAnnual, 79180)
        XCTAssertEqual(r.netPerPeriod, dec("6598.33"))
    }

    func testSemiMonthlyDividesByTwentyFour() throws {
        let r = try run(TakeHomeInput(grossAnnual: 60_000, payFrequency: .semiMonthly, stateCode: "TX"))
        XCTAssertEqual(r.federalIncomeTax, 5020)
        XCTAssertEqual(r.netAnnual, 50390)
        XCTAssertEqual(r.periodsPerYear, 24)
        XCTAssertEqual(r.netPerPeriod, dec("2099.58"))
    }

    func testMarriedWithChildrenGetsChildTaxCredit() throws {
        let r = try run(TakeHomeInput(grossAnnual: 150_000, filingStatus: .marriedJoint, stateCode: "TX", childrenUnder17: 2))
        XCTAssertEqual(r.federalIncomeTax, 10940)
        XCTAssertEqual(r.netAnnual, 127585)
    }

    func testChildCreditFullyPhasedOut() throws {
        let r = try run(TakeHomeInput(grossAnnual: 250_000, stateCode: "TX", childrenUnder17: 1))
        XCTAssertEqual(r.federalIncomeTax, 51304)
        XCTAssertEqual(r.socialSecurity, 11439)        // capped at the wage base
        XCTAssertEqual(r.medicare, 3625)
        XCTAssertEqual(r.additionalMedicare, 450)       // 0.9% of the $50,000 over $200,000
        XCTAssertEqual(r.netAnnual, 183182)
    }

    func testCaliforniaCreditAndBrackets() throws {
        let r = try run(TakeHomeInput(grossAnnual: 120_000, stateCode: "CA"))
        XCTAssertEqual(r.federalIncomeTax, 17570)
        XCTAssertEqual(r.stateIncomeTax, dec("6930.42"))
        XCTAssertEqual(r.netAnnual, dec("86319.58"))
    }

    func testCaliforniaMarriedThreeKidsHighIncome() throws {
        let r = try run(TakeHomeInput(grossAnnual: 300_000, filingStatus: .marriedJoint, stateCode: "CA", childrenUnder17: 3))
        XCTAssertEqual(r.federalIncomeTax, 42868)
        XCTAssertEqual(r.additionalMedicare, 450)
        XCTAssertEqual(r.stateIncomeTax, dec("18981.84"))
        XCTAssertEqual(r.netAnnual, dec("221911.16"))
    }

    func testPennsylvaniaTaxesFourOhOneKContributions() throws {
        let r = try run(TakeHomeInput(grossAnnual: 80_000, stateCode: "PA", preTax401kAnnual: 10_000))
        XCTAssertEqual(r.federalIncomeTax, 6570)
        XCTAssertEqual(r.stateIncomeTax, 2456)           // 3.07% of the full $80,000
        XCTAssertEqual(r.netAnnual, 54854)
    }

    func testOklahomaExcludesFourOhOneKContributions() throws {
        let r = try run(TakeHomeInput(grossAnnual: 80_000, stateCode: "OK", preTax401kAnnual: 10_000))
        XCTAssertEqual(r.stateIncomeTax, dec("2604.50"))
        XCTAssertEqual(r.netAnnual, dec("54705.50"))
    }

    func testFourOhOneKLowersIncomeTaxButNotFICA() throws {
        let r = try run(TakeHomeInput(grossAnnual: 60_000, stateCode: "TX", preTax401kAnnual: 6_000))
        XCTAssertEqual(r.federalIncomeTax, 4300)
        XCTAssertEqual(r.socialSecurity, 3720)
        XCTAssertEqual(r.medicare, 870)
        XCTAssertEqual(r.netAnnual, 45110)
    }

    func testSection125LowersIncomeTaxAndFICA() throws {
        let r = try run(TakeHomeInput(grossAnnual: 60_000, stateCode: "TX", preTaxSection125Annual: 6_000))
        XCTAssertEqual(r.federalIncomeTax, 4300)
        XCTAssertEqual(r.socialSecurity, 3348)
        XCTAssertEqual(r.medicare, 783)
        XCTAssertEqual(r.netAnnual, 45569)
    }

    func testNewYorkMarriedWithDeductionsAndDependents() throws {
        let r = try run(TakeHomeInput(
            grossAnnual: 200_000, filingStatus: .marriedJoint, stateCode: "NY",
            childrenUnder17: 2, preTaxSection125Annual: 5_000
        ))
        XCTAssertEqual(r.federalIncomeTax, 20840)
        XCTAssertEqual(r.socialSecurity, 11439)
        XCTAssertEqual(r.medicare, dec("2827.50"))
        XCTAssertEqual(r.stateIncomeTax, dec("9299.80"))
        XCTAssertEqual(r.netAnnual, dec("150593.70"))
    }

    func testHeadOfHouseholdWithChildAndOtherDependent() throws {
        let r = try run(TakeHomeInput(
            grossAnnual: 90_000, filingStatus: .headOfHousehold, stateCode: "GA",
            childrenUnder17: 1, otherDependents: 1
        ))
        XCTAssertEqual(r.federalIncomeTax, 4848)
        XCTAssertEqual(r.stateIncomeTax, 3633)
        XCTAssertEqual(r.netAnnual, 74634)
    }

    func testMassachusettsFlatRateWithExemption() throws {
        let r = try run(TakeHomeInput(grossAnnual: 70_000, stateCode: "MA"))
        XCTAssertEqual(r.stateIncomeTax, 3280)
    }

    func testZeroIncome() throws {
        let r = try run(TakeHomeInput(grossAnnual: 0, stateCode: "CA"))
        XCTAssertEqual(r.totalTaxes, 0)
        XCTAssertEqual(r.netAnnual, 0)
        XCTAssertEqual(r.effectiveTaxRate, 0)
    }

    func testNegativeInputsAreTreatedAsZero() throws {
        let r = try run(TakeHomeInput(
            grossAnnual: -5_000, stateCode: "CA", childrenUnder17: -2,
            preTax401kAnnual: -100, postTaxDeductionsAnnual: -50
        ))
        XCTAssertEqual(r.grossAnnual, 0)
        XCTAssertEqual(r.netAnnual, 0)
    }

    func testDeductionsCannotExceedGross() throws {
        let r = try run(TakeHomeInput(grossAnnual: 10_000, stateCode: "TX", preTax401kAnnual: 50_000))
        XCTAssertEqual(r.preTax401k, 10_000)
        XCTAssertEqual(r.netAnnual, 0)
    }

    func testStateCodeIsCaseInsensitive() throws {
        let lower = try run(TakeHomeInput(grossAnnual: 120_000, stateCode: "ca"))
        let upper = try run(TakeHomeInput(grossAnnual: 120_000, stateCode: "CA"))
        XCTAssertEqual(lower, upper)
    }

    func testUnknownStateThrows() {
        XCTAssertThrowsError(try run(TakeHomeInput(grossAnnual: 50_000, stateCode: "ZZ"))) { error in
            XCTAssertEqual(error as? TakeHomeError, .unknownState("ZZ"))
        }
    }

    func testEveryJurisdictionCalculatesSanely() throws {
        for option in Fixtures.data.stateOptions {
            for status in FilingStatus.allCases {
                let r = try run(TakeHomeInput(
                    grossAnnual: 85_000, filingStatus: status, stateCode: option.code, childrenUnder17: 1
                ))
                XCTAssertGreaterThanOrEqual(r.stateIncomeTax, 0, "\(option.code) \(status)")
                XCTAssertLessThan(r.stateIncomeTax, 85_000 * dec("0.15"), "\(option.code) \(status)")
                XCTAssertGreaterThan(r.netAnnual, 0, "\(option.code) \(status)")
                if !option.hasIncomeTax { XCTAssertEqual(r.stateIncomeTax, 0, option.code) }
            }
        }
    }

    func testResultReportsApproximateStates() throws {
        XCTAssertTrue(try run(TakeHomeInput(grossAnnual: 50_000, stateCode: "CA")).stateIsApproximate)
        XCTAssertFalse(try run(TakeHomeInput(grossAnnual: 50_000, stateCode: "TX")).stateIsApproximate)
    }
}

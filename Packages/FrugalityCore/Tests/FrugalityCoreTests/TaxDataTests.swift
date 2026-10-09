import XCTest
@testable import FrugalityCore

final class TaxDataTests: XCTestCase {
    func testLoadsAllFiftyStatesAndDC() {
        XCTAssertEqual(Fixtures.data.states.count, 51)
        XCTAssertTrue(Fixtures.data.states.contains { $0.code == "DC" })
    }

    func testNoIncomeTaxStates() {
        let expected: Set<String> = ["AK", "FL", "NV", "NH", "SD", "TN", "TX", "WA", "WY"]
        let actual = Set(Fixtures.data.states.filter { !$0.hasIncomeTax }.map(\.code))
        XCTAssertEqual(actual, expected)
    }

    func testRatesAreExactDecimals() {
        let nc = Fixtures.data.states.first { $0.code == "NC" }
        XCTAssertEqual(nc?.brackets?.single.first?.rate, dec("0.0399"))
        XCTAssertEqual(Fixtures.data.federal.socialSecurity.rate, dec("0.062"))
        XCTAssertEqual(Fixtures.data.federal.medicare.rate, dec("0.0145"))
    }

    func testFederalFigures() {
        let federal = Fixtures.data.federal
        XCTAssertEqual(federal.year, 2026)
        XCTAssertEqual(federal.standardDeduction.single, 16100)
        XCTAssertEqual(federal.socialSecurity.wageBase, 184500)
        XCTAssertEqual(federal.brackets.single.count, 7)
        XCTAssertEqual(federal.brackets.marriedJoint.count, 7)
        XCTAssertEqual(federal.brackets.headOfHousehold.count, 7)
    }

    func testValidationRejectsUnsortedBrackets() {
        var data = Fixtures.data
        let bad = [TaxBracket(from: 0, rate: dec("0.1")), TaxBracket(from: 0, rate: dec("0.2"))]
        data = TaxYearData(
            federal: FederalTaxData(
                year: data.federal.year, standardDeduction: data.federal.standardDeduction,
                brackets: StatusBrackets(single: bad, marriedJoint: bad, headOfHousehold: bad),
                socialSecurity: data.federal.socialSecurity, medicare: data.federal.medicare,
                childTaxCredit: data.federal.childTaxCredit
            ),
            states: data.states
        )
        XCTAssertThrowsError(try data.validate())
    }

    func testMissingYearThrows() {
        XCTAssertThrowsError(try TaxYearData.load(year: 1999)) { error in
            XCTAssertEqual(error as? TaxDataError, .missingFile("tax/1999/federal.json"))
        }
    }
}

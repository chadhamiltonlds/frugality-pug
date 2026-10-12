import Foundation
import FrugalityCore

@MainActor
final class RentVsBuyViewModel: ObservableObject {
    @Published var input: RentVsBuyInput {
        didSet {
            JSONStore.save(input, key: .rentVsBuy)
            result = RentVsBuyCalculator.compare(input)
        }
    }
    @Published private(set) var result: RentVsBuyResult

    init() {
        let saved = JSONStore.load(RentVsBuyInput.self, key: .rentVsBuy) ?? RentVsBuyInput()
        input = saved
        result = RentVsBuyCalculator.compare(saved)
    }
}

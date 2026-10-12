import Foundation

/// Default budget categories and keyword-based category suggestions for expense names.
public enum BudgetCategories {
    public static let housing = "Housing"
    public static let utilities = "Utilities"
    public static let food = "Food"
    public static let transportation = "Transportation"
    public static let insurance = "Insurance"
    public static let healthcare = "Healthcare"
    public static let debt = "Debt payments"
    public static let savings = "Savings & investing"
    public static let kids = "Kids & education"
    public static let pets = "Pets"
    public static let personal = "Personal & shopping"
    public static let entertainment = "Entertainment & travel"
    public static let giving = "Giving"
    public static let other = "Other"

    public static let defaults: [String] = [
        housing, utilities, food, transportation, insurance, healthcare, debt,
        savings, kids, pets, personal, entertainment, giving, other
    ]

    /// Defaults followed by custom categories (trimmed, blanks and case-insensitive duplicates removed).
    public static func all(custom: [String]) -> [String] {
        var result = defaults
        var seen = Set(defaults.map { $0.lowercased() })
        for name in custom {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
        }
        return result
    }

    /// Checked in order; the first rule with a matching keyword wins. Multi-word keywords match as phrases,
    /// single words match whole words (or their plural with -s or -es).
    private static let rules: [(category: String, keywords: [String])] = [
        (savings, ["401k", "401", "403b", "ira", "roth", "savings", "save", "invest", "investing", "brokerage", "529", "hsa", "emergency fund"]),
        (debt, ["loan", "debt", "credit card", "minimum payment"]),
        (insurance, ["insurance", "premium"]),
        (housing, ["rent", "mortgage", "hoa", "property tax", "apartment", "lawn", "home"]),
        (utilities, ["electric", "electricity", "water", "gas bill", "trash", "sewer", "internet", "wifi", "phone", "cell", "utility", "utilities"]),
        (pets, ["pet", "vet", "dog", "cat", "grooming", "kennel"]),
        (food, ["grocery", "groceries", "food", "restaurant", "dining", "coffee", "takeout", "doordash", "lunch", "dinner"]),
        (transportation, ["gas", "fuel", "car", "auto", "uber", "lyft", "parking", "toll", "transit", "bus", "train", "registration"]),
        (healthcare, ["doctor", "dentist", "dental", "medical", "pharmacy", "prescription", "therapy", "health", "vision", "gym"]),
        (kids, ["daycare", "childcare", "tuition", "school", "kid", "babysitter", "lesson", "camp"]),
        (giving, ["tithe", "tithing", "church", "charity", "donation", "gift"]),
        (entertainment, ["netflix", "spotify", "hulu", "disney", "subscription", "movie", "golf", "hobby", "game", "entertainment", "vacation", "travel", "concert"]),
        (personal, ["clothes", "clothing", "amazon", "shopping", "haircut", "personal", "target", "walmart", "costco"])
    ]

    /// Suggested category for an expense name, or `other` when nothing matches.
    public static func suggest(for name: String) -> String {
        let lower = name.lowercased()
        let words = Set(lower.split { !$0.isLetter && !$0.isNumber }.map(String.init))
        for rule in rules {
            for keyword in rule.keywords {
                let matches = keyword.contains(" ")
                    ? lower.contains(keyword)
                    : words.contains(keyword) || words.contains(keyword + "s") || words.contains(keyword + "es")
                if matches { return rule.category }
            }
        }
        return other
    }
}

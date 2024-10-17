
extension SelectionRequirement {
	init(_ numberOfAccounts: RequestedQuantity) {
		switch numberOfAccounts.quantifier {
		case .exactly:
			self = .exactly(Int(numberOfAccounts.quantity))
		case .atLeast:
			self = .atLeast(Int(numberOfAccounts.quantity))
		}
	}
}

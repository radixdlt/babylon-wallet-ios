import DesignSystem
import Profile

extension SelectionRequirement {
	public init(_ numberOfAccounts: Profile.Network.AuthorizedDapp.AuthorizedPersonaSimple.SharedAccounts.NumberOfAccounts) {
		switch numberOfAccounts.quantifier {
		case .exactly:
			self = .exactly(numberOfAccounts.quantity)
		case .atLeast:
			self = .atLeast(numberOfAccounts.quantity)
		}
	}
}

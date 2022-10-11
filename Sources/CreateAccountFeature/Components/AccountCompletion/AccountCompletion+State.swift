import Address
import Common
import Foundation

// MARK: - AccountCompletion.State
public extension AccountCompletion {
	struct State: Equatable {
		public let accountName: String
		public let accountAddress: Address
		public let origin: Origin

		public init(
			accountName: String,
			accountAddress: Address,
			origin: Origin
		) {
			self.accountName = accountName
			self.accountAddress = accountAddress
			self.origin = origin
		}
	}
}

// MARK: - AccountCompletion.State.Origin
public extension AccountCompletion.State {
	enum Origin: String {
		case home

		var displayText: String {
			switch self {
			case .home:
				return L10n.CreateAccount.Completion.Origin.home
			}
		}
	}
}

#if DEBUG
public extension AccountCompletion.State {
	static let placeholder: Self = .init(
		accountName: "My main account",
		accountAddress: .random,
		origin: .home
	)
}
#endif

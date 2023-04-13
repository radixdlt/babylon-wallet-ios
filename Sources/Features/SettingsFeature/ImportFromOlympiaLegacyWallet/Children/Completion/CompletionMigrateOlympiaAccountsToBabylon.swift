import FeaturePrelude
import Profile

// MARK: - CompletionMigrateOlympiaAccountsToBabylon
public struct CompletionMigrateOlympiaAccountsToBabylon: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let migratedAccounts: Profile.Network.Accounts
		public init(
			migratedAccounts: Profile.Network.Accounts
		) {
			self.migratedAccounts = migratedAccounts
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case copyAddress(AccountAddress)
		case finishButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case finishedMigration
	}

	@Dependency(\.pasteboardClient) private var pasteboardClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .finishButtonTapped:
			return .send(.delegate(.finishedMigration))
		case let .copyAddress(address):
			pasteboardClient.copyString(address.address)
			return .none
		}
	}
}

import FeaturePrelude
import ImportLegacyWalletClient

// MARK: - AccountsToImport
public struct AccountsToImport: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public let scannedAccounts: [ImportableAccount]

		public init(
			networkID: NetworkID,
			scannedAccounts: NonEmpty<OrderedSet<OlympiaAccountToMigrate>>
		) {
			@Dependency(\.engineToolkitClient) var engineToolkitClient

			self.scannedAccounts = scannedAccounts.map { account in
				let babylonAddress = try? engineToolkitClient.deriveVirtualAccountAddress(.init(
					publicKey: .ecdsaSecp256k1(account.publicKey.intoEngine()),
					networkId: networkID
				))

				return .init(
					accountName: account.displayName?.rawValue,
					olympiaAddress: account.address,
					bablyonAddress: babylonAddress,
					appearanceID: .fromIndex(Int(account.addressIndex)),
					olympiaAccountType: account.accountType
				)
			}
		}

		public struct ImportableAccount: Sendable, Hashable, Identifiable {
			public var id: LegacyOlympiaAccountAddress { olympiaAddress }
			public let accountName: String?
			public let olympiaAddress: LegacyOlympiaAccountAddress
			public let bablyonAddress: ComponentAddress?
			public let appearanceID: Profile.Network.Account.AppearanceID
			public let olympiaAccountType: Olympia.AccountType
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case continueImport
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .continueButtonTapped:
			return .send(.delegate(.continueImport))
		}
	}
}

import EngineToolkitModels
import Prelude

// MARK: - MigratedHardwareAccounts
public struct MigratedHardwareAccounts: Sendable, Hashable {
	public let networkID: NetworkID

	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>
	public var babylonAccounts: Profile.Network.Accounts {
		.init(rawValue: .init(uncheckedUniqueElements: self.accounts.rawValue.elements.map(\.babylon)))!
	}

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		guard accounts.allSatisfy({ $0.olympia.accountType == .hardware }) else {
			throw ExpectedHardwareAccount()
		}
		self.networkID = networkID
		self.accounts = accounts
	}
}

import NonEmpty
import OrderedCollections
import Sargon

// MARK: - MigratedSoftwareAccounts
public struct MigratedSoftwareAccounts: Sendable, Hashable {
	public let networkID: NetworkID

	public let accounts: NonEmpty<OrderedSet<MigratedAccount>>

	public var babylonAccounts: Accounts {
		Accounts(accounts.rawValue.elements.map(\.babylon))
	}

	public let factorSourceToSave: DeviceFactorSource?

	public init(
		networkID: NetworkID,
		accounts: NonEmpty<OrderedSet<MigratedAccount>>,
		factorSourceToSave: DeviceFactorSource?
	) throws {
		guard accounts.allSatisfy({ $0.babylon.networkID == networkID }) else {
			throw NetworkIDDisrepancy()
		}
		guard accounts.allSatisfy({ $0.olympia.accountType == .software }) else {
			throw ExpectedSoftwareAccount()
		}
		self.networkID = networkID
		self.accounts = accounts
		self.factorSourceToSave = factorSourceToSave
	}
}

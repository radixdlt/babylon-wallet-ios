import NonEmpty
import OrderedCollections
import Sargon

// MARK: - MigratedSoftwareAccounts
struct MigratedSoftwareAccounts: Sendable, Hashable {
	let networkID: NetworkID

	let accounts: NonEmpty<OrderedSet<MigratedAccount>>

	var babylonAccounts: Accounts {
		Accounts(accounts.rawValue.elements.map(\.babylon))
	}

	let factorSourceToSave: DeviceFactorSource?

	init(
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

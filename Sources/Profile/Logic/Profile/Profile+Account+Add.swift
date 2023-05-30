import Cryptography
import EngineToolkit
import Prelude

// MARK: - PersonaNotConnected
struct PersonaNotConnected: Swift.Error {}

// MARK: - AccountAlreadyExists
struct AccountAlreadyExists: Swift.Error {}

extension Profile.Network.Accounts {
	// FIXME: uh terrible, please fix this.
	@discardableResult
	public mutating func appendAccount(_ account: Profile.Network.Account) -> Profile.Network.Account {
		var identifiedArrayOf = self.rawValue
		let (wasInserted, _) = identifiedArrayOf.append(account)
		assert(wasInserted, "We expected this to be a new, unique, Account, thus we expected it to be have been inserted, but it was not. Maybe all properties except the AccountAddress was unique, and the reason why address was not unique is probably due to the fact that the wrong 'index' in the derivation path was use (same reused), due to bad logic in `storage` of the factor.")
		self = .init(rawValue: identifiedArrayOf)!
		return account
	}

	// FIXME: uh terrible, please fix this.
	public mutating func updateAccount(_ account: Profile.Network.Account) throws {
		var identifiedArrayOf = self.rawValue
		guard identifiedArrayOf.updateOrAppend(account) != nil else {
			assertionFailure("We expected this account to already exist, but it did not.")
			throw TryingToUpdateAnAccountWhichIsNotAlreadySaved()
		}

		self = .init(rawValue: identifiedArrayOf)!
	}
}

// MARK: - TryingToUpdateAnAccountWhichIsNotAlreadySaved
struct TryingToUpdateAnAccountWhichIsNotAlreadySaved: Swift.Error {}

extension Profile {
	/// Updates an `Account` in the profile
	public mutating func updateAccount(
		_ account: Profile.Network.Account
	) throws {
		var network = try network(id: account.networkID)
		try network.accounts.updateAccount(account)
		try updateOnNetwork(network)
	}

	/// Saves an `Account` into the profile
	public mutating func addAccount(
		_ account: Profile.Network.Account,
		shouldUpdateFactorSourceNextDerivationIndex: Bool = true
	) throws {
		let networkID = account.networkID
		// can be nil if this is a new network
		let maybeNetwork = try? network(id: networkID)

		if var network = maybeNetwork {
			guard !network.accounts.contains(where: { $0 == account }) else {
				throw AccountAlreadyExists()
			}
			network.accounts.appendAccount(account)
			try updateOnNetwork(network)
		} else {
			let network = Profile.Network(
				networkID: networkID,
				accounts: .init(rawValue: .init(uniqueElements: [account]))!,
				personas: [],
				authorizedDapps: []
			)
			try networks.add(network)
		}

		guard shouldUpdateFactorSourceNextDerivationIndex else {
			return
		}
		switch account.securityState {
		case let .unsecured(entityControl):
			let factorSourceID = entityControl.transactionSigning.factorSourceID
			try self.factorSources.updateFactorSource(id: factorSourceID) {
				try $0.increaseNextDerivationIndex(for: account.kind, networkID: account.networkID)
			}
		}
	}
}

extension FactorSource {
	public mutating func increaseNextDerivationIndex(
		for entityKind: EntityKind,
		networkID: NetworkID
	) throws {
		switch self {
		case var .device(deviceFactorSource):
			deviceFactorSource.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
			self = deviceFactorSource.embed()
		case var .ledger(ledger): // FIXME: Post-MFA remove this
			ledger.nextDerivationIndicesPerNetwork?.increaseNextDerivationIndex(for: entityKind, networkID: networkID)
			self = ledger.embed()
		default:
			throw DisrepancyFactorSourceWrongKind(expected: .device, actual: kind)
		}
	}
}

// MARK: - DisrepancyFactorSourceWrongKind
public struct DisrepancyFactorSourceWrongKind: Swift.Error {
	public let expected: FactorSourceKind
	public let actual: FactorSourceKind
}

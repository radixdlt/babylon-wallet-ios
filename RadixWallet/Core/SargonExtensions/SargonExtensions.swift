import SargonUniFFI

extension Profile.Network.Account.AppearanceID {
	init(sargon: Sargon.AppearanceID) {
		self.init(rawValue: sargon.value)!
	}

	func intoSargon() -> Sargon.AppearanceID {
		Sargon.AppearanceID(value: self.rawValue)
	}
}

extension EntityFlag {
	func intoSargon() -> Sargon.EntityFlag {
		switch self {
		case .deletedByUser: Sargon.EntityFlag.deletedByUser
		}
	}
}

extension NonFungibleResourceIndicator {
	public var ids: [NonFungibleLocalId] {
		switch self {
		case let .byIds(ids):
			ids
		case let .byAll(_, ids), let .byAmount(_, ids):
			ids.value
		}
	}
}

extension Address {
	public func into<A: AddressProtocol>(type: A.Type = A.self) throws -> A {
		try A(validatingAddress: self.address)
	}
}

extension OrderedSet<EntityFlag> {
	func intoSargon() -> [Sargon.EntityFlag] {
		map { $0.intoSargon() }
	}
}

extension Sargon.DisplayName {
	init(wallet: NonEmptyString) {
		try! self.init(validating: wallet.rawValue)
	}
}

extension ThirdPartyDeposits.DepositRule {
	func intoSargon() -> Sargon.DepositRule {
		switch self {
		case .acceptAll: Sargon.DepositRule.acceptAll
		case .acceptKnown: Sargon.DepositRule.acceptKnown
		case .denyAll: Sargon.DepositRule.denyAll
		}
	}
}

extension ThirdPartyDeposits.AssetException {
	func intoSargon() -> Sargon.AssetException {
		Sargon.AssetException(address: self.address, exceptionRule: self.exceptionRule.intoSargon())
	}
}

extension ThirdPartyDeposits.DepositorAddress {
	func intoSargon() -> Sargon.ResourceOrNonFungible {
		switch self {
		case let .nonFungibleGlobalID(globalID): Sargon.ResourceOrNonFungible.nonFungible(value: globalID)
		case let .resourceAddress(resourceAddress): Sargon.ResourceOrNonFungible.resource(value: resourceAddress)
		}
	}
}

extension ThirdPartyDeposits.DepositAddressExceptionRule {
	func intoSargon() -> Sargon.DepositAddressExceptionRule {
		switch self {
		case .allow: Sargon.DepositAddressExceptionRule.allow
		case .deny: Sargon.DepositAddressExceptionRule.deny
		}
	}
}

extension ThirdPartyDeposits {
	func intoSargon() -> Sargon.ThirdPartyDeposits {
		Sargon.ThirdPartyDeposits(
			depositRule: self.depositRule.intoSargon(),
			assetsExceptionList: self.assetsExceptionSet().map { $0.intoSargon() },
			depositorsAllowList: self.depositorsAllowSet().map { $0.intoSargon() }
		)
	}
}

extension Profile.Network.Account.OnLedgerSettings {
	func intoSargon() -> Sargon.OnLedgerSettings {
		Sargon.OnLedgerSettings(thirdPartyDeposits: self.thirdPartyDeposits.intoSargon())
	}
}

extension PlaintextMessage {
	public var messageString: String {
		switch self.message {
		case let .binaryMessage(binary): String(data: binary, encoding: .utf8) ?? binary.hex
		case let .stringMessage(plaintext): plaintext
		}
	}
}

public func == (lhs: Address, rhs: some AddressProtocol) -> Bool {
	lhs == rhs.embed()
}

public func == (lhs: some AddressProtocol, rhs: Address) -> Bool {
	rhs == lhs
}

extension Profile.Network.Account {
	public func intoSargon() -> Sargon.Account {
		Sargon.Account(
			networkId: self.networkID,
			address: self.accountAddress,
			displayName: Sargon.DisplayName(wallet: self.displayName),
			securityState: self.securityState.intoSargon(),
			appearanceId: self.appearanceID.intoSargon(),
			flags: self.flags.intoSargon(),
			onLedgerSettings: self.onLedgerSettings.intoSargon()
		)
	}
}

extension FactorSourceKind {
	func intoSargon() -> Sargon.FactorSourceKind {
		switch self {
		case .device: Sargon.FactorSourceKind.device
		case .ledgerHQHardwareWallet: Sargon.FactorSourceKind.ledgerHqHardwareWallet
		case .offDeviceMnemonic: Sargon.FactorSourceKind.offDeviceMnemonic
		case .trustedContact: Sargon.FactorSourceKind.trustedContact
		case .securityQuestions: Sargon.FactorSourceKind.securityQuestions
		}
	}
}

extension FactorSourceID.FromHash {
	func intoSargon() -> Sargon.FactorSourceIdFromHash {
		try! Sargon.FactorSourceIdFromHash(
			kind: self.kind.intoSargon(),
			body: .init(bytes: self.body.data.data)
		)
	}
}

extension LegacyOlympiaBIP44LikeDerivationPath {
	func intoSargon() -> Sargon.BIP44LikePath {
		try! Sargon.BIP44LikePath(string: self.derivationPath)
	}
}

extension IdentityHierarchicalDeterministicDerivationPath {
	func intoSargon() -> Sargon.IdentityPath {
		try! Sargon.IdentityPath(string: self.derivationPath)
	}
}

extension DerivationPath {
	func intoSargon() -> Sargon.DerivationPath {
		if isGetID {
			return Sargon.DerivationPath.cap26(value: .getId(value: .default))
		}

		if let olympiaAccountPath = try? self.asLegacyOlympiaBIP44LikePath() {
			return Sargon.DerivationPath.bip44Like(value: olympiaAccountPath.intoSargon())
		} else if let _ = try? self.asAccountPath() {
			return try! Sargon.DerivationPath.cap26(
				value: .account(
					value: Sargon.AccountPath(string: self.path)
				)
			)
		} else if let identityPath = try? self.asIdentityPath() {
			return Sargon.DerivationPath.cap26(value: .identity(value: identityPath.intoSargon()))
		} else {
			fatalError("unknown path")
		}
	}
}

extension HierarchicalDeterministicPublicKey {
	func intoSargon() -> Sargon.HierarchicalDeterministicPublicKey {
		Sargon.HierarchicalDeterministicPublicKey(publicKey: self.publicKey.intoSargon(), derivationPath: self.derivationPath.intoSargon())
	}
}

extension HierarchicalDeterministicFactorInstance {
	func intoSargon() -> Sargon.HierarchicalDeterministicFactorInstance {
		Sargon.HierarchicalDeterministicFactorInstance(
			factorSourceId: self.factorSourceID.intoSargon(),
			publicKey: self.hierarchicalDeterministicPublicKey.intoSargon()
		)
	}
}

extension UnsecuredEntityControl {
	func intoSargon() -> Sargon.UnsecuredEntityControl {
		Sargon.UnsecuredEntityControl(
			transactionSigning: self.transactionSigning.intoSargon(),
			authenticationSigning: self.authenticationSigning?.intoSargon()
		)
	}
}

extension EntitySecurityState {
	public func intoSargon() -> Sargon.EntitySecurityState {
		switch self {
		case let .unsecured(uec): Sargon.EntitySecurityState.unsecured(value: uec.intoSargon())
		}
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> StakeClaim {
		fatalError()
	}
}

extension ResourceIndicator {
	public var resourceAddress: ResourceAddress {
		switch self {
		case let .fungible(resourceAddress, _): resourceAddress
		case let .nonFungible(resourceAddress, _): resourceAddress
		}
	}
}

extension FungibleResourceIndicator {
	public var amount: Decimal192 {
		switch self {
		case let .guaranteed(decimal: amount): amount
		case let .predicted(predictedDecimal): predictedDecimal.value
		}
	}
}

extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		self == self.mapTo(networkID: networkID)
	}
}

// MARK: - DependencyInformation + CustomStringConvertible
extension DependencyInformation: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .branch(value): value
		case let .tag(value): value
		case let .version(value): value
		case let .rev(value): value
		}
	}
}

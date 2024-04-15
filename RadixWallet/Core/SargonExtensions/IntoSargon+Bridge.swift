import CryptoKit
import Foundation
import Sargon
import SargonUniFFI

extension EntitySecurityState {
	public func intoSargon() -> Sargon.EntitySecurityState {
		switch self {
		case let .unsecured(uec): Sargon.EntitySecurityState.unsecured(value: uec.intoSargon())
		}
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> Sargon.StakeClaim {
		Sargon.StakeClaim(
			validatorAddress: self.validatorAddress,
			resourceAddress: self.token.id.resourceAddress.asNonFungibleResourceAddress!,
			ids: [self.id.nonFungibleLocalId],
			amount: self.claimAmount.nominalAmount
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

extension Profile.Network.Account.OnLedgerSettings {
	func intoSargon() -> Sargon.OnLedgerSettings {
		Sargon.OnLedgerSettings(thirdPartyDeposits: self.thirdPartyDeposits.intoSargon())
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

extension OrderedSet<EntityFlag> {
	func intoSargon() -> [Sargon.EntityFlag] {
		map { $0.intoSargon() }
	}
}

extension EntityFlag {
	func intoSargon() -> Sargon.EntityFlag {
		switch self {
		case .deletedByUser: Sargon.EntityFlag.deletedByUser
		}
	}
}

extension Profile.Network.Account.AppearanceID {
	func intoSargon() -> Sargon.AppearanceID {
		Sargon.AppearanceID(value: self.rawValue)
	}
}

extension SLIP10.PublicKey {
	public func intoSargon() -> Sargon.PublicKey {
		try! Sargon.PublicKey(bytes: self.compressedData)
	}
}

extension SLIP10.Signature {
	public func intoSargon() -> Sargon.Signature {
		try! Sargon.Signature(bytes: self.serialize())
	}
}

extension K1.PublicKey {
	public func intoSargon() -> Sargon.Secp256k1PublicKey {
		try! Sargon.Secp256k1PublicKey(bytes: self.compressedRepresentation)
	}
}

extension SignatureWithPublicKey {
	public func intoSargon() -> Sargon.SignatureWithPublicKey {
		switch self {
		case let .ecdsaSecp256k1(signature, publicKey):
			Sargon.SignatureWithPublicKey.secp256k1(
				publicKey: publicKey.intoSargon(),
				signature: signature.intoSargon()
			)
		case let .eddsaEd25519(signature, publicKey):
			Sargon.SignatureWithPublicKey.ed25519(
				publicKey: publicKey.intoSargon(),
				signature: Sargon.Ed25519Signature(
					wallet: signature
				)
			)
		}
	}
}

extension K1.ECDSAWithKeyRecovery.Signature {
	func intoSargon() -> Sargon.Secp256k1Signature {
		try! Sargon.Secp256k1Signature(bytes: self.radixSerialize())
	}
}

extension Curve25519.Signing.PublicKey {
	func intoSargon() -> Sargon.Ed25519PublicKey {
		try! Sargon.Ed25519PublicKey(bytes: self.compressedRepresentation)
	}
}

// MARK: From Wallet
extension Sargon.DisplayName {
	init(wallet: NonEmptyString) {
		try! self.init(validating: wallet.rawValue)
	}
}

extension Sargon.Ed25519Signature {
	init(wallet: EdDSASignature) {
		try! self.init(bytes: wallet)
	}
}

// MARK: Into Wallet
extension Profile.Network.Account.AppearanceID {
	init(sargon: Sargon.AppearanceID) {
		self.init(rawValue: sargon.value)!
	}
}

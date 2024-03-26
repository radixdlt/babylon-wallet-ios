import Foundation

// MARK: - Sargon
public enum Sargon {}

// MARK: Declare Manifests
extension TransactionManifest {
	public static func thirdPartyDepositUpdate(
		to new: ThirdPartyDeposits
	) -> Self {
		sargon()
	}

	public static func faucet(
		includeLockFeeInstruction: Bool,
		addressOfReceivingAccount: AccountAddress
	) -> Self {
		sargon()
	}

	public static func setOwnerKeys(
		addressOfAccountOrPersona: AddressOfAccountOrPersona,
		ownerKeyHashes: [RETPublicKeyHash]
	) -> Self {
		sargon()
	}

	public static func createFungibleToken(
		addressOfOwner: AccountAddress
	) -> Self {
		sargon()
	}

	public static func createMultipleFungibleTokens(
		addressOfOwner: AccountAddress
	) -> Self {
		sargon()
	}

	public static func createMultipleNonFungibleTokens(
		addressOfOwner: AccountAddress
	) -> Self {
		sargon()
	}

	public static func createNonFungibleToken(
		addressOfOwner: AccountAddress
	) -> Self {
		sargon()
	}

	public static func markingAccountAsDappDefinitionType(
		accountAddress: AccountAddress
	) -> Self {
		sargon()
	}

	public static func stakesClaim(
		accountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) -> Self {
		sargon()
	}

	public static func assetsTransfers(
		transfers: PerAssetTransfers
	) -> Self {
		sargon()
	}

	public func modify(
		lockFee fee: Decimal192 = .temporaryStandardFee,
		addressOfFeePayer: AccountAddress
	) -> Self {
		sargon()
	}

	public func modify(
		addGuarantees guarantees: [TransactionGuarantee]
	) -> Self {
		sargon()
	}
}

extension ResourceAddress {
	/// Returns the XRD resource on network identified by `networkID`.
	public static func xrd(on networkID: NetworkID) -> Self {
		sargon()
	}

	public var isXRD: Bool {
		sargon()
	}
}

extension SargonBuildInformation {
	public static func get() -> Self {
		sargon()
	}
}

public func debugPrintCompiledNotarizedIntent(data: Data) -> String {
	sargon()
}

extension Data {
	func hash() -> Data {
		sargon()
	}
}

extension LegacyOlympiaAccountAddress {
	public init(publicKey: K1.PublicKey) {
		sargon()
	}
}

extension AccountAddress {
	public func wasMigratedFromLegacyOlympia(address legacy: LegacyOlympiaAccountAddress) -> Bool {
		sargon()
	}

	public init(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) {
		sargon()
	}
}

extension IdentityAddress {
	public init(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) {
		sargon()
	}
}

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
		lockFee fee: RETDecimal = .temporaryStandardFee,
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

extension Sargon {
	/// REQUIRES NETWORK CALL (and probable cache)	///
	public static func needsSignatureForDepositting(
		intoAccount: Profile.Network.Account,
		resource: ResourceAddress
	) async throws -> Bool {
		sargon()
	}

	public static func buildInformation() -> SargonBuildInformation {
		SargonBuildInformation()
	}

	public static func hash(data: Data) -> Data {
		sargon()
	}

	public static func xrdAddressOfNetwork(networkId: NetworkID) -> ResourceAddress {
		sargon()
	}

	public static func nonFungibleLocalIdAsStr(value: NonFungibleLocalId) -> String {
		sargon()
	}

	public static func nonFungibleLocalIdFromStr(string: String) throws -> NonFungibleLocalId {
		sargon()
	}

	public static func debugPrintCompiledNotarizedIntent(data: Data) -> String {
		sargon()
	}

	public static func deriveOlympiaMainnetAccountAddressFromPublicKey(
		publicKey: K1.PublicKey
	) throws -> LegacyOlympiaAccountAddress {
		sargon()
	}

	public static func deriveVirtualAccountAddressFromPublicKey(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) throws -> AccountAddress {
		sargon()
	}

	public static func deriveVirtualIdentityAddressFromPublicKey(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) throws -> IdentityAddress {
		sargon()
	}
}

import Foundation

// MARK: - Sargon
public enum Sargon {}

// MARK: Declare Manifests
extension TransactionManifest {
	public static func thirdPartyDepositUpdate(
		to new: ThirdPartyDeposits
	) throws -> (manifest: TransactionManifest, updatedAccount: Profile.Network.Account) {
		sargon()
	}

	public static func faucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		addressOfReceivingAccount: AccountAddress
	) throws -> TransactionManifest {
		sargon()
	}

	public static func setOwnerKeys(
		addressOfAccountOrPersona: AddressOfAccountOrPersona,
		ownerKeyHashes: [RETPublicKeyHash],
		networkId: NetworkID
	) -> TransactionManifest {
		sargon()
	}

	public static func createFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func createMultipleFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func createMultipleNonFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func createNonFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func markingAccountAsDappDefinitionType(
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		sargon()
	}

	public static func stakesClaim(
		accountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) throws -> TransactionManifest {
		sargon()
	}

	public static func assetsTransfers(
		transfers: PerAssetTransfers
	) -> TransactionManifest {
		sargon()
	}

	public func modify(
		lockFee fee: RETDecimal = .temporaryStandardFee,
		addressOfFeePayer: AccountAddress
	) throws -> TransactionManifest {
		sargon()
	}

	public func modify(
		addGuarantees guarantees: [TransactionGuarantee]
	) throws -> TransactionManifest {
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

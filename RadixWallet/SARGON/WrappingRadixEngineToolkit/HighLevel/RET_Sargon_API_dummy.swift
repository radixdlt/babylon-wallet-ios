import Foundation

// MARK: - Sargon
public enum Sargon {}

// MARK: Declare Manifests
extension Sargon {
	public static func manifestThirdPartyDepositUpdate(
		to new: ThirdPartyDeposits
	) throws -> (manifest: TransactionManifest, updatedAccount: Profile.Network.Account) {
		sargon()
	}

	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		addressOfReceivingAccount: AccountAddress
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestSetOwnerKeys(
		addressOfAccountOrPersona: AddressOfAccountOrPersona,
		ownerKeyHashes: [RETPublicKeyHash],
		networkId: NetworkID
	) -> TransactionManifest {
		sargon()
	}

	public static func manifestForCreateFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestForCreateMultipleFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestForCreateNonFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestMarkingAccountAsDappDefinitionType(
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		sargon()
	}

	public static func manifestStakesClaim(
		accountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) throws -> TransactionManifest {
		sargon()
	}

	/// REQUIRES NETWORK CALL (and probable cache)
	public static func manifestAssetsTransfers(
		transfers: AssetsTransfersTransactionPrototype,
		message: String?
	) async throws -> TransactionManifest {
		sargon()
	}
}

extension Sargon {
	public static func updatingManifestLockFee(
		_ manifest: TransactionManifest,
		addressOfFeePayer: AccountAddress,
		fee: RETDecimal = .temporaryStandardFee
	) throws -> TransactionManifest {
		sargon()
	}

	public static func updatingManifestAddGuarantees(
		_ manifest: TransactionManifest,
		guarantees: [TransactionGuarantee]
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

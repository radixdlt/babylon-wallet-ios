import Foundation

// MARK: - Sargon
public enum Sargon {}

// MARK: Declare Manifests
extension Sargon {
	public static func manifestThirdPartyDepositUpdate(
		to new: ThirdPartyDeposits
	) throws -> (manifest: TransactionManifest, updatedAccount: Profile.Network.Account) {
		panic()
	}

	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		addressOfReceivingAccount: AccountAddress
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestSetOwnerKeys(
		addressOfAccountOrPersona: AddressOfAccountOrPersona,
		ownerKeyHashes: [RETPublicKeyHash],
		networkId: NetworkID
	) -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateMultipleFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateMultipleNonFungibleTokens(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestForCreateNonFungibleToken(
		addressOfOwner: AccountAddress,
		networkID: NetworkID
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestMarkingAccountAsDappDefinitionType(
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		panic()
	}

	public static func manifestStakesClaim(
		accountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) throws -> TransactionManifest {
		panic()
	}

	/// REQUIRES NETWORK CALL (and probable cache)
	public static func manifestAssetsTransfers(
		transfers: AssetsTransfersTransactionPrototype,
		message: String?
	) async throws -> TransactionManifest {
		panic()
	}
}

extension Sargon {
	public static func updatingManifestLockFee(
		_ manifest: TransactionManifest,
		addressOfFeePayer: AccountAddress,
		fee: RETDecimal = .temporaryStandardFee
	) throws -> TransactionManifest {
		panic()
	}

	public static func updatingManifestAddGuarantees(
		_ manifest: TransactionManifest,
		guarantees: [TransactionGuarantee]
	) throws -> TransactionManifest {
		panic()
	}
}

extension Sargon {
	/// REQUIRES NETWORK CALL (and probable cache)	///
	public static func needsSignatureForDepositting(
		intoAccount: Profile.Network.Account,
		resource: ResourceAddress
	) async throws -> Bool {
		panic()
	}

	public static func buildInformation() -> BuildInformation {
		BuildInformation(version: "Sargon MOCKED")
	}

	public static func hash(data: Data) -> Data {
		panic()
	}

	public static func xrdAddressOfNetwork(networkId: NetworkID) -> ResourceAddress {
		panic()
	}

	public static func nonFungibleLocalIdAsStr(value: NonFungibleLocalId) -> String {
		panic()
	}

	public static func nonFungibleLocalIdFromStr(string: String) throws -> NonFungibleLocalId {
		panic()
	}

	public static func deriveOlympiaMainnetAccountAddressFromPublicKey(
		publicKey: K1.PublicKey
	) throws -> AccountAddress {
		panic()
	}

	public static func deriveVirtualAccountAddressFromPublicKey(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) throws -> AccountAddress {
		panic()
	}

	public static func deriveVirtualIdentityAddressFromPublicKey(
		publicKey: SLIP10.PublicKey,
		networkId: NetworkID
	) throws -> IdentityAddress {
		panic()
	}
}

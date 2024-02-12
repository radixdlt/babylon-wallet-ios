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

	public static func manifestWithdrawAmount(
		from: AccountAddress,
		resource: ResourceAddress,
		amount: RETDecimal
	) -> ManifestBuilder.InstructionsChain.Instruction {
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

	/// REQUIRES NETWORK CALL (and probable cache)	///
	public static func needsSignatureForDepositting(
		intoAccount: Profile.Network.Account,
		resource: ResourceAddress
	) async throws -> Bool {
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
	public static func buildInformation() -> BuildInformation {
		BuildInformation(version: "Sargon MOCKED")
	}

	public static func hash(data: Data) -> Data {
		panic()
	}
}

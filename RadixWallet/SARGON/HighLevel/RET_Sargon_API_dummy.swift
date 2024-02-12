import Foundation

public enum Sargon {
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

	public static func buildInformation() -> BuildInformation {
		BuildInformation(version: "Sargon MOCKED")
	}

	public static func hash(data: Data) -> Data {
		panic()
	}
}

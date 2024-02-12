import Foundation

public enum Sargon {
	public static func manifestThirdPartyDepositUpdate(
		to new: ThirdPartyDeposits
	) throws -> (manifest: TransactionManifest, updatedAccount: Profile.Network.Account) {
		panic()
	}

	// MARK: Global Functions
	public static func buildInformation() -> BuildInformation {
		BuildInformation(version: "Sargon MOCKED")
	}
}

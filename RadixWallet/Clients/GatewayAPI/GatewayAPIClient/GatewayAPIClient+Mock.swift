// MARK: - GatewayAPIClient + TestDependencyKey
extension GatewayAPIClient: TestDependencyKey {
	static let previewValue = Self.mock()

	static let testValue = Self(
		getNetworkName: unimplemented("\(Self.self).getNetworkName"),
		getEpoch: unimplemented("\(Self.self).getEpoch"),
		getEntityDetails: unimplemented("\(Self.self).getEntityDetails"),
		getEntityMetadata: unimplemented("\(Self.self).getEntityMetadata"),
		getEntityMetadataPage: unimplemented("\(Self.self).getEntityMetadataPage"),
		getEntityFungiblesPage: unimplemented("\(Self.self).getEntityFungiblesPage"),
		getEntityFungibleResourceVaultsPage: unimplemented("\(Self.self).getEntityFungibleResourceVaultsPage"),
		getEntityNonFungiblesPage: unimplemented("\(Self.self).getEntityNonFungiblesPage"),
		getEntityNonFungibleResourceVaultsPage: unimplemented("\(Self.self).getEntityNonFungibleResourceVaultsPage"),
		getEntityNonFungibleIdsPage: unimplemented("\(Self.self).getEntityNonFungibleIdsPage"),
		getNonFungibleData: unimplemented("\(Self.self).getNonFungibleData"),
		getAccountLockerTouchedAt: unimplemented("\(Self.self).getAccountLockerTouchedAt"),
		getAccountLockerVaults: unimplemented("\(Self.self).GetAccountLockerVaults"),
		transactionPreview: unimplemented("\(Self.self).transactionPreview"),
		streamTransactions: unimplemented("\(Self.self).streamTransactions"),
		prevalidateDeposit: unimplemented("\(Self.self).prevalidateDeposit")
	)

	// TODO: convert to noop, don't use in tests.
	private static func mock(
		fungibleResourceCount _: Int = 2,
		nonFungibleResourceCount _: Int = 2,
		submittedTXIsDoubleSpend: Bool = false,
		txStatus: GatewayAPI.TransactionStatus? = nil
	) -> Self {
		.init(
			getNetworkName: { _ in .init("Nebunet") },
			getEpoch: { 123 },
			getEntityDetails: unimplemented("\(self).getEntityDetails"),
			getEntityMetadata: unimplemented("\(self).getEntityMetadata"),
			getEntityMetadataPage: unimplemented("\(self).getEntityMetadataPage"),
			getEntityFungiblesPage: unimplemented("\(self).getEntityFungiblesPage"),
			getEntityFungibleResourceVaultsPage: unimplemented("\(self).getEntityFungibleResourceVaultsPage"),
			getEntityNonFungiblesPage: unimplemented("\(self).getEntityNonFungiblesPage"),
			getEntityNonFungibleResourceVaultsPage: unimplemented("\(self).getEntityNonFungibleResourceVaultsPage"),
			getEntityNonFungibleIdsPage: unimplemented("\(self).getEntityNonFungibleIdsPage"),
			getNonFungibleData: unimplemented("\(self).getNonFungibleData"),
			getAccountLockerTouchedAt: unimplemented("\(Self.self).getAccountLockerTouchedAt"),
			getAccountLockerVaults: unimplemented("\(Self.self).GetAccountLockerVaults"),
			transactionPreview: unimplemented("\(self).transactionPreview"),
			streamTransactions: unimplemented("\(self).streamTransactions"),
			prevalidateDeposit: unimplemented("\(Self.self).prevalidateDeposit")
		)
	}
}

extension DependencyValues {
	var gatewayAPIClient: GatewayAPIClient {
		get { self[GatewayAPIClient.self] }
		set { self[GatewayAPIClient.self] = newValue }
	}
}

extension GatewayAPI.LedgerState {
	static let previewValue = Self(
		network: "Network name",
		stateVersion: 0,
		proposerRoundTimestamp: "",
		epoch: 1337,
		round: 0
	)
}

private let fungibleResourceAddresses = [
	"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs3ydc4g",
	"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqpqtc26ta",
	"resource_rdx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzq6kmakh",
	"resource_rdx1qqe4m2jlrz5y82syz3y76yf9ztd4trj7fmlq4vf4gmzs0ct3fm",
]

private func fungibleResourceAddress(at index: Int) -> String {
	fungibleResourceAddresses[index % fungibleResourceAddresses.count]
}

private let nonFungibleResourceAddresses = [
	"resource_rdx1qqllllllllllllllllllllllllllllllllllluqqqqqsrwgwsn",
	"resource_rdx1qqlllllllllllllllllll242llllllllllllluqqqqpqj4fkfl",
	"resource_rdx1qqlllllllllllllllllllwamllllllllllllluqqqqpstghvxt",
	"resource_rdx1qqlllllllllllllllllllnxvllllllllllllluqqqqzqtul9u0",
]

private func nonFungibleResourceAddress(at index: Int) -> String {
	nonFungibleResourceAddresses[index % nonFungibleResourceAddresses.count]
}

extension Data {
	private var asUInt: UInt {
		withUnsafeBytes { $0.load(as: UInt.self) }
	}
}

private func amount(at index: Int) -> UInt {
	UInt(index.data.hashValue)
}

private func amountAttos(at index: Int) -> String {
	String(amount(at: index))
}

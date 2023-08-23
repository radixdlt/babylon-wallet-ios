import ClientPrelude
import Cryptography
import EngineKit

// MARK: - GatewayAPIClient + TestDependencyKey
extension GatewayAPIClient: TestDependencyKey {
	public static let previewValue = Self.mock()

	public static let testValue = Self(
		getNetworkName: unimplemented("\(Self.self).getNetworkName"),
		getEpoch: unimplemented("\(Self.self).getEpoch"),
		getEntityDetails: unimplemented("\(Self.self).getEntityDetails"),
		getEntityMetadata: unimplemented("\(Self.self).getEntityMetadata"),
		getEntityFungiblesPage: unimplemented("\(Self.self).getEntityFungiblesPage"),
		getEntityFungibleResourceVaultsPage: unimplemented("\(Self.self).getEntityFungibleResourceVaultsPage"),
		getEntityNonFungiblesPage: unimplemented("\(Self.self).getEntityNonFungiblesPage"),
		getEntityNonFungibleResourceVaultsPage: unimplemented("\(Self.self).getEntityNonFungibleResourceVaultsPage"),
		getEntityNonFungibleIdsPage: unimplemented("\(Self.self).getEntityNonFungibleIdsPage"),
		getNonFungibleData: unimplemented("\(Self.self).getNonFungibleData"),
		submitTransaction: unimplemented("\(Self.self).submitTransaction"),
		transactionStatus: unimplemented("\(Self.self).transactionStatus"),
		transactionPreview: unimplemented("\(Self.self).transactionPreview")
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
			getEpoch: { .init(rawValue: 123) },
			getEntityDetails: unimplemented("\(self).getEntityDetails"),
			getEntityMetadata: unimplemented("\(self).getEntityMetadata"),
			getEntityFungiblesPage: unimplemented("\(self).getEntityFungiblesPage"),
			getEntityFungibleResourceVaultsPage: unimplemented("\(self).getEntityFungibleResourceVaultsPage"),
			getEntityNonFungiblesPage: unimplemented("\(self).getEntityNonFungiblesPage"),
			getEntityNonFungibleResourceVaultsPage: unimplemented("\(self).getEntityNonFungibleResourceVaultsPage"),
			getEntityNonFungibleIdsPage: unimplemented("\(self).getEntityNonFungibleIdsPage"),
			getNonFungibleData: unimplemented("\(self).getNonFungibleData"),
			submitTransaction: { _ in
				.init(duplicate: submittedTXIsDoubleSpend)
			},
			transactionStatus: { _ in
				.init(
					ledgerState: .previewValue,
					status: .committedSuccess,
					knownPayloads: [.init(payloadHash: "payload-hash-hex", status: .committedSuccess)],
					errorMessage: nil
				)
			},
			transactionPreview: unimplemented("\(self).transactionPreview")
		)
	}
}

extension DependencyValues {
	public var gatewayAPIClient: GatewayAPIClient {
		get { self[GatewayAPIClient.self] }
		set { self[GatewayAPIClient.self] = newValue }
	}
}

extension GatewayAPI.LedgerState {
	public static let previewValue = Self(
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

extension FixedWidthInteger {
	fileprivate var data: Data {
		let data = withUnsafeBytes(of: self) { Data($0) }
		return data
	}
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

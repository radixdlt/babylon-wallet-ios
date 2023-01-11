import CryptoKit
import Foundation
import Mnemonic
import Prelude
import Profile
import XCTestDynamicOverlay

// MARK: - GatewayAPIClient + TestDependencyKey
extension GatewayAPIClient: TestDependencyKey {
	public static let previewValue = Self.mock()

	public static let testValue = Self(
		getNetworkName: unimplemented("\(Self.self).getNetworkName"),
		getEpoch: unimplemented("\(Self.self).getEpoch"),
		accountResourcesByAddress: unimplemented("\(Self.self).accountResourcesByAddress"),
		resourcesOverview: unimplemented("\(Self.self).resourcesOverview"),
		resourceDetailsByResourceIdentifier: unimplemented("\(Self.self).resourceDetailsByResourceIdentifier"),
		getNonFungibleIds: unimplemented("\(Self.self).getNonFungibleIds"),
		submitTransaction: unimplemented("\(Self.self).submitTransaction"),
		transactionStatus: unimplemented("\(Self.self).transactionStatus")
	)

	private static func mock(
		fungibleResourceCount _: Int = 2,
		nonFungibleResourceCount _: Int = 2,
		submittedTXIsDoubleSpend: Bool = false,
		txStatus: GatewayAPI.TransactionStatus? = nil
	) -> Self {
		.init(
			getNetworkName: { _ in .init("Nebunet") },
			getEpoch: { .init(rawValue: 123) },
			accountResourcesByAddress: unimplemented("\(Self.self).accountResourcesByAddress"),
			resourcesOverview: unimplemented("\(Self.self).resourcesOverview"),
			resourceDetailsByResourceIdentifier: unimplemented("\(Self.self).resourceDetailsByResourceIdentifier"),
			getNonFungibleIds: unimplemented("\(Self.self).getNonFungibleIds"),
			submitTransaction: { _ in
				.init(duplicate: submittedTXIsDoubleSpend)
			},
			transactionStatus: { _ in
				.init(
					ledgerState: .init(
						network: "Network name",
						stateVersion: 0,
						proposerRoundTimestamp: "",
						epoch: 1337,
						round: 0
					),
					status: .committedSuccess,
					knownPayloads: [.init(payloadHashHex: "payload-hash-hex", status: .committedSuccess)],
					errorMessage: nil
				)
			}
		)
	}
}

public extension DependencyValues {
	var gatewayAPIClient: GatewayAPIClient {
		get { self[GatewayAPIClient.self] }
		set { self[GatewayAPIClient.self] = newValue }
	}
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

private extension FixedWidthInteger {
	var data: Data {
		let data = withUnsafeBytes(of: self) { Data($0) }
		return data
	}
}

private extension Data {
	var asUInt: UInt {
		withUnsafeBytes { $0.load(as: UInt.self) }
	}
}

private func amount(at index: Int) -> UInt {
	Data(SHA256.hash(data: index.data)).asUInt
}

private func amountAttos(at index: Int) -> String {
	String(amount(at: index))
}

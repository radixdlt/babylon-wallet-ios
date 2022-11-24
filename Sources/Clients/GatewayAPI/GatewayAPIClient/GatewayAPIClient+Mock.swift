import CryptoKit
import Dependencies
import Foundation
import Mnemonic
import Profile
import XCTestDynamicOverlay

// MARK: - GatewayAPIClient + TestDependencyKey
extension GatewayAPIClient: TestDependencyKey {
	public static let previewValue = Self.mock()

	public static let testValue = Self(
		getCurrentBaseURL: unimplemented("\(Self.self).getCurrentBaseURL"),
		setCurrentBaseURL: unimplemented("\(Self.self).setCurrentBaseURL"),
		getGatewayInfo: unimplemented("\(Self.self).getGatewayInfo"),
		getEpoch: unimplemented("\(Self.self).getEpoch"),
		accountResourcesByAddress: unimplemented("\(Self.self).accountResourcesByAddress"),
		resourcesOverview: unimplemented("\(Self.self).resourcesOverview"),
		resourceDetailsByResourceIdentifier: unimplemented("\(Self.self).resourceDetailsByResourceIdentifier"),
		recentTransactions: unimplemented("\(Self.self).recentTransactions"),
		submitTransaction: unimplemented("\(Self.self).submitTransaction"),
		transactionStatus: unimplemented("\(Self.self).transactionStatus"),
		transactionDetails: unimplemented("\(Self.self).transactionDetails")
	)

	private static func mock(
		fungibleResourceCount _: Int = 2,
		nonFungibleResourceCount _: Int = 2,
		submittedTXIsDoubleSpend: Bool = false,
		txStatus: GatewayAPI.TransactionStatus? = nil
	) -> Self {
		.init(
			getCurrentBaseURL: { URL(string: "example.com")! },
			setCurrentBaseURL: { _ in AppPreferences.NetworkAndGateway.primary },
			getGatewayInfo: { .init(
				ledgerState: .init(
					network: "Network name",
					stateVersion: 0,
					timestamp: "",
					epoch: 1337,
					round: 0
				),
				knownTarget: .init(stateVersion: 0),
				releaseInfo: .init(
					releaseVersion: "release-version",
					openApiSchemaVersion: "schema-version"
				)
			) },
			getEpoch: { .init(rawValue: 123) },
			accountResourcesByAddress: { _ in
				fatalError()
			},
			resourcesOverview: { _ in
				fatalError()
			},
			resourceDetailsByResourceIdentifier: { _ in
				fatalError()
			},
			recentTransactions: { _ in
				.init(
					ledgerState: .init(
						network: "Network name",
						stateVersion: 0,
						timestamp: "",
						epoch: 1337,
						round: 0
					),
					items: []
				)
			},
			submitTransaction: { _ in
				.init(duplicate: submittedTXIsDoubleSpend)
			},
			transactionStatus: { _ in
				.init(
					ledgerState: .init(
						network: "Network name",
						stateVersion: 0,
						timestamp: "",
						epoch: 1337,
						round: 0
					),
					transaction: .init(
						transactionStatus: .init(status: .succeeded),
						payloadHashHex: "payload-hash-hex",
						intentHashHex: "intent-hash-hex"
					)
				)
			},
			transactionDetails: { _ in
				.init(
					ledgerState: .init(
						network: "Network name",
						stateVersion: 0,
						timestamp: "",
						epoch: 1337,
						round: 0
					),
					transaction: .init(
						transactionStatus: .init(status: .succeeded),
						payloadHashHex: "payload-hash-hex",
						intentHashHex: "intent-hash-hex"
					),
					details: .init(
						rawHex: "raw-hex",
						referencedGlobalEntities: []
					)
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

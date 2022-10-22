#if DEBUG
import CryptoKit
import Foundation
import Mnemonic
import XCTestDynamicOverlay

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
	var data: Data {
		let data = withUnsafeBytes(of: self) { Data($0) }
		return data
	}
}

extension Data {
	var asUInt: UInt {
		withUnsafeBytes { $0.load(as: UInt.self) }
	}
}

func amount(at index: Int) -> UInt {
	Data(SHA256.hash(data: index.data)).asUInt
}

func amountAttos(at index: Int) -> String {
	String(amount(at: index))
}

public extension GatewayAPIClient {
	static let unimplemented = Self(
		getEpoch: XCTUnimplemented("\(Self.self).getEpoch is unimplemented"),
		accountResourcesByAddress: XCTUnimplemented("\(Self.self).accountResourcesByAddress is unimplemented"),
		resourceDetailsByResourceIdentifier: XCTUnimplemented("\(Self.self).resourceDetailsByResourceIdentifier is unimplemented"),
		submitTransaction: XCTUnimplemented("\(Self.self).submitTransaction is unimplemented"),
		transactionStatus: XCTUnimplemented("\(Self.self).transactionStatus is unimplemented")
	)

	static func mock(
		fungibleResourceCount: Int = 2,
		nonFungibleResourceCount: Int = 2,
		submittedTXIsDoubleSpend: Bool = false,
		txStatus: TransactionStatus.Status? = nil
	) -> Self {
		.init(
			getEpoch: { .init(epoch: 1337) },
			accountResourcesByAddress: { accountAddress in
				.init(
					address: accountAddress.address,
					fungibleResources: .init(
						totalCount: fungibleResourceCount,
						results: (0 ..< fungibleResourceCount).map { index in
							EntityStateResponseFungibleResource(
								address: fungibleResourceAddress(at: index),
								amountAttos: amountAttos(at: index)
							)
						}
					),
					nonFungibleResources: .init(
						totalCount: nonFungibleResourceCount,
						results: (0 ..< nonFungibleResourceCount).map { index in
							EntityStateResponseNonFungibleResource(
								address: nonFungibleResourceAddress(at: index),
								amount: Double(amount(at: index))
							)
						}
					)
				)
			},
			resourceDetailsByResourceIdentifier: { resourceAddress in
				let seed = resourceAddress.hashValue
				let seed1 = resourceAddress.count.hashValue
				let seed2 = resourceAddress.count.bitWidth.hashValue
				let fun: EntityDetailsResponseDetails = .typeEntityDetailsResponseFungibleDetails(
					.init(
						resourceType: "fungible",
						isFungible: true,
						totalSupplyAttos: amountAttos(at: seed),
						totalMintedAttos: amountAttos(at: seed1),
						totalBurntAttos: amountAttos(at: seed2)
					)
				)

				let nonFun: EntityDetailsResponseDetails = .typeEntityDetailsResponseNonFungibleDetails(
					.init(
						resourceType: "non_fungible",
						isFungible: false,
						tbd: "Unknown undecided property made more unique by seeded value: \(seed)"
					)
				)

				if let _ = nonFungibleResourceAddresses.firstIndex(of: resourceAddress) {
					return nonFun
				} else if let _ = fungibleResourceAddresses.firstIndex(of: resourceAddress) {
					return fun
				} else if seed.isMultiple(of: 2) {
					return nonFun
				} else {
					return fun
				}
			},
			submitTransaction: { _ in
				.init(duplicate: submittedTXIsDoubleSpend)
			},
			transactionStatus: { request in
				.init(
					ledgerState: .init(
						network: "mockNET",
						version: 0,
						timestamp: String(describing: Date().timeIntervalSince1970),
						epoch: 1337,
						round: 237
					),
					transaction: .init(
						transactionStatus: .init(
							status: txStatus ?? TransactionStatus.Status(seed: request.transactionIdentifier.hashValue)
						),

						payloadHashHex: Data(SHA256.hash(data: "payloadHashHex\(request.transactionIdentifier.valueHex)".data(using: .utf8)!)).hexEncodedString(),

						intentHashHex: Data(SHA256.hash(data: "intentHashHex\(request.transactionIdentifier.valueHex)".data(using: .utf8)!)).hexEncodedString(),

						transactionAccumulatorHex: Data(SHA256.hash(data: "transactionAccumulatorHex\(request.transactionIdentifier.valueHex)".data(using: .utf8)!)).hexEncodedString(),

						feePaid: TokenAmount(value: "\(request.transactionIdentifier.hashValue)", tokenIdentifier: .init(rri: "resource_rdx1xrd"))
					)
				)
			}
		)
	}
}

private extension TransactionStatus.Status {
	init(seed: Int) {
		switch seed % 4 {
		case 0: self = .succeeded
		case 1: self = .pending
		case 2: self = .failed
		case 3: self = .rejected
		default: self = .succeeded
		}
	}
}
#endif

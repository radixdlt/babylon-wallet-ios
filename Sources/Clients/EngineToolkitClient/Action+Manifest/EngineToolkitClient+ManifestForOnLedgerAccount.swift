import EngineToolkit
import Foundation
import Profile
import SLIP10

// MARK: - Network.KnownAddresses
public extension Network {
	struct KnownAddresses: Sendable, Hashable {
		public let faucet: ComponentAddress

		/// For creation of On-Ledger accounts (non-virtual)
		public let createAccountComponent: PackageAddress

		public let xrd: ResourceAddress

		public init(faucet: ComponentAddress, createAccountComponent: PackageAddress, xrd: ResourceAddress) {
			self.faucet = faucet
			self.createAccountComponent = createAccountComponent
			self.xrd = xrd
		}
	}
}

public extension Network.KnownAddresses {
	static let hammunet = Self(
		faucet: "component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973",
		createAccountComponent: "package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf",
		xrd: "resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw"
	)
}

// FIXME: - betanet: add betanet knownAddress here for faucet and XRD
private let knownAddressByNetworkID: [NetworkID: Network.KnownAddresses] = [
	.hammunet: .hammunet,
]

// MARK: - NoKnownAddressForNetworkID
public struct NoKnownAddressForNetworkID: LocalizedError {
	public let unknownNetworkID: NetworkID
	public var errorDescription: String? {
		"\(Self.self)(unknownNetworkID: \(unknownNetworkID)"
	}
}

public extension EngineToolkitClient {
	func manifestForOnLedgerAccount(
		networkID: NetworkID,
		publicKey: PublicKey
	) throws -> TransactionManifest {
		try manifestForOnLedgerAccount(
			networkID: networkID,
			publicKey: publicKey.intoEngine()
		)
	}

	func lockFeeCallMethod(
		address: ComponentAddress,
		fee: Decimal = 10.0
	) -> CallMethod {
		CallMethod(
			receiver: address,
			methodName: "lock_fee"
		) {
			Decimal_(value: fee)
		}
	}

	private func knownAddresses(for networkID: NetworkID) throws -> Network.KnownAddresses {
		guard let knownAddresses = knownAddressByNetworkID[networkID] else {
			throw NoKnownAddressForNetworkID(unknownNetworkID: networkID)
		}
		return knownAddresses
	}

	private func faucetAddress(for networkID: NetworkID) throws -> ComponentAddress {
		try knownAddresses(for: networkID).faucet
	}

	func lockFeeCallMethod(
		faucetForNetwork networkID: NetworkID,
		fee: Decimal = 10.0
	) throws -> CallMethod {
		let faucetAddress = try faucetAddress(for: networkID)
		return lockFeeCallMethod(address: faucetAddress, fee: fee)
	}

	func manifestForOnLedgerAccount(
		networkID: NetworkID,
		publicKey: Engine.PublicKey
	) throws -> TransactionManifest {
		let engineToolkit = EngineToolkit()

		let nonFungibleAddressString = try engineToolkit.deriveNonFungibleAddressFromPublicKeyRequest(
			request: publicKey
		)
		.get()
		.nonFungibleAddress

		let knownAddresses = try knownAddresses(for: networkID)
		let faucetAddress = knownAddresses.faucet
		let nonFungibleAddress = try NonFungibleAddress(hex: nonFungibleAddressString)

		return TransactionManifest {
			lockFeeCallMethod(address: faucetAddress)
			CallMethod(
				receiver: faucetAddress,
				methodName: "free"
			)

			let xrdBucket: Bucket = "xrd"

			TakeFromWorktop(resourceAddress: knownAddresses.xrd, bucket: xrdBucket)

			CallFunction(
				packageAddress: knownAddresses.createAccountComponent,
				blueprintName: "Account",
				functionName: "new_with_resource"
			) {
				Enum("Protected") {
					Enum("ProofRule") {
						Enum("Require") {
							Enum("StaticNonFungible") {
								nonFungibleAddress
							}
						}
					}
				}
				xrdBucket
			}
		}
	}
}

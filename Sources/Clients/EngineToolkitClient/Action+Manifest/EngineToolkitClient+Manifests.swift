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

	func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		try manifestForFaucet(
			includeLockFeeInstruction: includeLockFeeInstruction,
			networkID: networkID,
			componentAddress: .init(address: accountAddress.address)
		)
	}

	/// CALL_METHOD
	///     ComponentAddress("${faucet_component}")
	///     "lock_fee"
	///     Decimal("10");
	/// CALL_METHOD
	///     ComponentAddress("${faucet_component}")
	///     "free_xrd";
	///
	/// CALL_METHOD
	///     ComponentAddress("${account_component_address}")
	///     "deposit"
	///     Expression("ENTIRE_WORKTOP");
	func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: ComponentAddress
	) throws -> TransactionManifest {
		let knownAddresses = try knownAddresses(for: networkID)
		let faucetAddress = knownAddresses.faucet
		var instructions: [any InstructionProtocol] = [
			CallMethod(
				receiver: faucetAddress,
				methodName: "free"
			),

			CallMethod(
				receiver: componentAddress,
				methodName: "deposit"
			) {
				Expression("ENTIRE_WORKTOP")
			},
		]

		if includeLockFeeInstruction {
			instructions.insert(
				lockFeeCallMethod(address: faucetAddress),
				at: 0
			)
		}
		return .init(instructions: .json(instructions.map { $0.embed() }))
	}
}

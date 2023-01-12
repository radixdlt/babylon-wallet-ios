import ClientPrelude
import Cryptography
import EngineToolkit
import Profile

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
	static let addressMap: [NetworkID: Network.KnownAddresses] = [
		.nebunet: .nebunet,
		.gilganet: .gilganet,
		.enkinet: .enkinet,
		.hammunet: .hammunet,
		.mardunet: .mardunet,
	]

	static let nebunet = Self(
		faucet: "component_tdx_b_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qdxyth4",
		createAccountComponent: "package_tdx_b_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlssf7lg2",
		xrd: "resource_tdx_b_1qzkcyv5dwq3r6kawy6pxpvcythx8rh8ntum6ws62p95s9hhz9x"
	)

	static let gilganet = Self(
		faucet: "component_tdx_20_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlnye7x",
		createAccountComponent: "package_tdx_20_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlskx38d7",
		xrd: "resource_tdx_20_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfgndge"
	)

	static let enkinet = Self(
		faucet: "component_tdx_21_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlrqh7e",
		createAccountComponent: "package_tdx_21_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlskk4fdp",
		xrd: "resource_tdx_21_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfchrgx"
	)

	static let hammunet = Self(
		faucet: "component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973",
		createAccountComponent: "package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf",
		xrd: "resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw"
	)
	static let mardunet = Self(
		faucet: "component_tdx_24_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlp5g7p",
		createAccountComponent: "package_tdx_24_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk5pkde",
		xrd: "resource_tdx_24_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqf6rug7"
	)
}

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
		fee: String = "10"
	) -> CallMethod {
		CallMethod(
			receiver: address,
			methodName: "lock_fee"
		) {
			Decimal_(value: fee)
		}
	}

	private func knownAddresses(for networkID: NetworkID) throws -> Network.KnownAddresses {
		guard let knownAddresses = Network.KnownAddresses.addressMap[networkID] else {
			throw NoKnownAddressForNetworkID(unknownNetworkID: networkID)
		}
		return knownAddresses
	}

	private func faucetAddress(for networkID: NetworkID) throws -> ComponentAddress {
		try knownAddresses(for: networkID).faucet
	}

	func lockFeeCallMethod(
		faucetForNetwork networkID: NetworkID,
		fee: String = "10"
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
	///
	/// CALL_METHOD
	///     ComponentAddress("${faucet_component}")
	///     "free";
	///
	/// CALL_METHOD
	///     ComponentAddress("${account_component_address}")
	///     "deposit_batch"
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
				methodName: "deposit_batch"
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

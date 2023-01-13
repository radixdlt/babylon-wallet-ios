import ClientPrelude
import EngineToolkit

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

// MARK: - NoKnownAddressForNetworkID
public struct NoKnownAddressForNetworkID: LocalizedError {
	public let unknownNetworkID: NetworkID
	public var errorDescription: String? {
		"\(Self.self)(unknownNetworkID: \(unknownNetworkID)"
	}
}

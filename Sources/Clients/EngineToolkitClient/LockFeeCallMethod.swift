import ClientPrelude
import EngineToolkit

extension EngineToolkitClient {
	public func lockFeeCallMethod(
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

	public func lockFeeCallMethod(
		faucetForNetwork networkID: NetworkID,
		fee: String = "10"
	) throws -> CallMethod {
		let faucetAddress = try faucetAddress(for: networkID)
		return lockFeeCallMethod(address: faucetAddress, fee: fee)
	}

	public func manifestForFaucet(
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
	public func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: ComponentAddress
	) throws -> TransactionManifest {
		let faucetAddress = try faucetAddress(for: networkID)
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
		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}

	private func faucetAddress(for networkID: NetworkID) throws -> ComponentAddress {
		try knownEntityAddresses(networkID).faucetComponentAddress
	}
}

#if DEBUG
extension EngineToolkitClient {
	public func manifestForCreateFungibleToken(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		accountAddress: AccountAddress
	) throws -> TransactionManifest {
		//        let faucetAddress = try faucetAddress(for: networkID)
		//        var instructions: [any InstructionProtocol] = [
		//            CallMethod(
		//                receiver: faucetAddress,
		//                methodName: "free"
		//            ),
//
		//            CallMethod(
		//                receiver: componentAddress,
		//                methodName: "deposit_batch"
		//            ) {
		//                Expression("ENTIRE_WORKTOP")
		//            },
		//        ]
//
		//        if includeLockFeeInstruction {
		//            instructions.insert(
		//                lockFeeCallMethod(address: faucetAddress),
		//                at: 0
		//            )
		//        }
		//        return .init(instructions: .parsed(instructions.map { $0.embed() }))
		fatalError()
	}
}
#endif // DEBUG

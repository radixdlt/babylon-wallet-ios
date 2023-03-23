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
		networkID: NetworkID,
		accountAddress: AccountAddress,
		tokenDivisivility: UInt8 = 18,
		tokenName: String = "Test",
		tokenDescription: String = "A very innovative and important resource.",
		tokenSymbol: String = "TEST",
		initialSupply: String = "21000000"
	) throws -> TransactionManifest {
		let instructions: [any InstructionProtocol] = [
			CreateFungibleResourceWithInitialSupply(
				divisibility: tokenDivisivility,
				metadata: Map_(
					keyValueKind: .string,
					valueValueKind: .string,
					entries: [
						[.string("name"), .string(tokenName)],
						[.string("symbol"), .string(tokenSymbol)],
						[.string("description"), .string(tokenDescription)],
					]
				),

				accessRules: .init(
					keyValueKind: .enum,
					valueValueKind: .tuple,
					entries: [
						[.enum(.init(.string("ResourceMethodAuthKey::Withdraw"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
						[.enum(.init(.string("ResourceMethodAuthKey::Deposit"))), .tuple(.init(arrayLiteral: .enum(.init(.string("AccessRule::AllowAll"))), .enum(.init(.string("AccessRule::DenyAll")))))],
					]
				),
				initialSupply: .decimal(.init(value: initialSupply))
			),
		]

		return .init(instructions: .parsed(instructions.map { $0.embed() }))
	}
}
#endif // DEBUG

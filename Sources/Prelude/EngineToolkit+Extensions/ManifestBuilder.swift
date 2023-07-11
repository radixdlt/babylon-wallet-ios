import EngineToolkitUniFFI

extension TransactionManifest {
	public func withInstructionAdded(_ instruction: Instruction, at index: Int) throws -> TransactionManifest {
		var instructionList = instructions().instructionsList()
		instructionList.insert(instruction, at: index)

		return try .init(
			instructions: .fromInstructions(instructions: instructionList, networkId: instructions().networkId()),
			blobs: blobs()
		)
	}

	public func withLockFeeCallMethodAdded(
		address: Address,
		fee: String = "10"
	) throws -> TransactionManifest {
		try withInstructionAdded(
			.callMethod(
				address: .init(address: address.address),
				methodName: "lock_fee",
				args: .tupleValue(fields: [.decimalValue(value: .init(value: fee))])
			),
			at: 0
		)
	}

	public static func manifestForFaucet(
		includeLockFeeInstruction: Bool,
		networkID: NetworkID,
		componentAddress: Address
	) throws -> TransactionManifest {
		let faucet = utilsKnownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
		let raw = """
		CALL_METHOD
		    Address("\(faucet.addressString())")
		    "lock_fee"
		    Decimal("10");

		# Calling the "free" method on the faucet component which is the method responsible for dispensing
		# XRD from the faucet.
		CALL_METHOD
		    Address("\(faucet.addressString())")
		    "free";

		# Depositing all of the XRD dispensed from the faucet into our account component.
		CALL_METHOD
		    Address("\(componentAddress.address)")
		    "try_deposit_batch_or_abort"
		    Expression("ENTIRE_WORKTOP");

		"""
		let instructions = try Instructions.fromString(string: raw, blobs: [], networkId: networkID.rawValue)
		return TransactionManifest(
			instructions: instructions,
			blobs: []
		)
	}

//
	//        public func manifestForMultipleCreateFungibleToken(
	//                networkID: NetworkID,
	//                accountAddress: AccountAddress,
	//                tokensCount: Int = 20
	//        ) throws -> TransactionManifest {
	//                let faucetAddress = faucetAddress(networkID: networkID)
//
	//                let tokens: [Instruction] = stride(from: 0, to: tokensCount, by: 1).map { _ in
	//                        var metdataEntries: [[MetadataValue]] = []
//
	//                        let addName = Bool.random()
	//                        let addSymbol = Bool.random()
	//                        let addIcon = Bool.random()
	//                        let hasSupply = Bool.random()
	//                        let initialSupply = String(Int.random(in: 0 ..< 100_000))
	//                        let description = BIP39.randomPhrase(maxSize: 20)
//
	//                        if addName {
	//                                // compose name from two strings
	//                                let name = [BIP39.WordList.english.randomElement()?.capitalized ?? "Unknown", BIP39.WordList.english.randomElement() ?? "Unknown"].joined(separator: " ")
	//                                // add Name
	//                                metdataEntries.append([.stringValue(value: "name"), .stringValue(value: name)])
	//                        }
//
	//                        if addSymbol {
	//                                let symbol = BIP39.WordList.english.randomElement()?.capitalized ?? "Unknown"
	//                                // add symbol
	//                                metdataEntries.append(
	//                                        [.stringValue(value: "symbol"), .stringValue(value: symbol)]
	//                                )
	//                        }
//
	//                        if addIcon {
	//                                let url = "https://c4.wallpaperflare.com/wallpaper/817/534/563/ave-bosque-fantasia-fenix-wallpaper-preview.jpg"
//
	//                                metdataEntries.append(
	//                                        [.stringValue(value: "icon_url"), .urlValue(value: url)]
	//                                )
	//                        }
//
	//                        metdataEntries.append(
	//                                [.stringValue(value: "description"), .stringValue(value: description)]
	//                        )
//
	//                        let accessRules = Instruction.create
	//                }
	//        }

	func faucetAddress(networkID: NetworkID) -> EngineToolkitUniFFI.Address {
		utilsKnownAddresses(networkId: networkID.rawValue).componentAddresses.faucet
	}
}

extension Instruction {
	public static func lockFeeCall(
		address: Address,
		fee: String = "10"
	) throws -> Instruction {
		try .callMethod(address: .init(address: address.address), methodName: "lock_fee", args: .decimalValue(value: .init(value: fee)))
	}
}

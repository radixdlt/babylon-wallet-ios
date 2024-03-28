// MARK: - AssetsTransfersRecipient + Identifiable
extension AssetsTransfersRecipient: Identifiable {
	public typealias ID = AccountAddress
	public var id: ID {
		accountAddress
	}
}

extension NonFungibleLocalID {
	public func toUserFacingString() -> String {
		fatalError("sargon migration")
	}

	public func formatted(_ format: AddressFormat = .default) -> String {
		fatalError("sargon migration")
	}
}

extension NonFungibleGlobalID {
	public func formatted(_ format: AddressFormat = .default) -> String {
		fatalError("sargon migration")
	}
}

extension ResourceAddress {
	public func formatted(_ format: AddressFormat = .default) -> String {
		fatalError("sargon migration")
	}
}

extension Profile.Network.Account.AppearanceID {
	init(sargon: Sargon.AppearanceID) {
		self.init(rawValue: sargon.value)!
	}
}

extension PlaintextMessage {
	public var messageString: String {
		switch self.message {
		case let .binaryMessage(binary): String(data: binary, encoding: .utf8) ?? binary.hex
		case let .stringMessage(plaintext): plaintext
		}
	}
}

extension Profile.Network.Account {
	public func intoSargon() -> Sargon.Account {
		fatalError()
	}
}

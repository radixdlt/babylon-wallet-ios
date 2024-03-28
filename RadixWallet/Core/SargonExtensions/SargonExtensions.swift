import SargonUniFFI

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

public func == (lhs: Address, rhs: some AddressProtocol) -> Bool {
	lhs == rhs.embed()
}

public func == (lhs: some AddressProtocol, rhs: Address) -> Bool {
	rhs == lhs
}

extension Profile.Network.Account {
	public func intoSargon() -> Sargon.Account {
		fatalError()
	}
}

extension OnLedgerEntitiesClient.StakeClaim {
	public func intoSargon() -> StakeClaim {
		fatalError()
	}
}

extension ResourceIndicator {
	public var resourceAddress: ResourceAddress {
		switch self {
		case let .fungible(resourceAddress, _): resourceAddress
		case let .nonFungible(resourceAddress, _): resourceAddress
		}
	}
}

extension FungibleResourceIndicator {
	public var amount: Decimal192 {
		switch self {
		case let .guaranteed(decimal: amount): amount
		case let .predicted(predictedDecimal): predictedDecimal.value
		}
	}
}

extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		self == self.mapTo(networkID: networkID)
	}
}

// MARK: - DependencyInformation + CustomStringConvertible
extension DependencyInformation: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .branch(value): value
		case let .tag(value): value
		case let .version(value): value
		case let .rev(value): value
		}
	}
}

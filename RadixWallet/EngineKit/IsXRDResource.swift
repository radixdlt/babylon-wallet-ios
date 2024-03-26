extension ResourceAddress {
	/// Is this resource XRD on its own network
	public var isXRD: Bool {
		isXRD(on: networkID)
	}

	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}

	public static func xrd(on networkID: NetworkID) -> Self {
		try! EngineToolkit.Address.xrd(networkID.rawValue).asSpecific()
	}

	static let mainnetXRDAddress: ResourceAddress = .xrd(on: .mainnet)
}

extension SpecificAddress {
	var isOnMainnet: Bool {
		networkID == NetworkID.mainnet
	}
}

extension EngineToolkit.Address {
	static func xrd(_ networkId: UInt8) -> EngineToolkit.Address {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

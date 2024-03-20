extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}

	public static func xrd(on networkID: NetworkID) -> Self {
		try! EngineToolkit.Address.xrd(networkID.rawValue).asSpecific()
	}

	static let mainnetXRDAddress: ResourceAddress = .xrd(on: .mainnet)
}

extension EngineToolkit.Address {
	static func xrd(_ networkId: UInt8) -> EngineToolkit.Address {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

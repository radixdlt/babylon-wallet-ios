extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}
}

extension EngineToolkit.Address {
	static func xrd(_ networkId: UInt8) -> EngineToolkit.Address {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

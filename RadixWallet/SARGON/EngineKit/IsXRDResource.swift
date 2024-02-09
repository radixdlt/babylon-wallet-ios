extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}
}

extension EngineToolkitAddress {
	static func xrd(_ networkId: UInt8) -> EngineToolkitAddress {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

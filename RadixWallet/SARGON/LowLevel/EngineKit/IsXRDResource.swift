extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}
}

extension RETAddress {
	static func xrd(_ networkId: UInt8) -> RETAddress {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

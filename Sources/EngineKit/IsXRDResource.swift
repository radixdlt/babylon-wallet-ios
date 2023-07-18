extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) throws -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}
}

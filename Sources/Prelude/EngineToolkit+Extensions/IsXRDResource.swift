extension ResourceAddress {
        public func isXRD(on networkID: NetworkID) throws -> Bool {
                address == utilsKnownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
        }
}

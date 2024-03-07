extension ResourceAddress {
	public func isXRD(on networkID: NetworkID) -> Bool {
		address == knownAddresses(networkId: networkID.rawValue).resourceAddresses.xrd.addressString()
	}

	public static func xrd(on networkID: NetworkID) throws -> Self {
		try EngineToolkit.Address.xrd(networkID.rawValue).asSpecific()
	}

	static var mainnetXRDAddress: ResourceAddress {
		(try? xrd(on: .mainnet)) ?? ResourceAddress(
			address: "resource_rdx1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxradxrd",
			decodedKind: .globalFungibleResourceManager
		)
	}
}

extension EngineToolkit.Address {
	static func xrd(_ networkId: UInt8) -> EngineToolkit.Address {
		knownAddresses(networkId: networkId).resourceAddresses.xrd
	}
}

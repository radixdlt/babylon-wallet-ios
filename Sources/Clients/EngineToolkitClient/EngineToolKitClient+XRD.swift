import ClientPrelude
import EngineToolkit

extension EngineToolkitClient {
	public func isXRD(resource: ResourceAddress, on networkID: NetworkID) throws -> Bool {
		try isXRD(address: resource.address, on: networkID)
	}

	private func isXRD(address: String, on networkID: NetworkID) throws -> Bool {
		try address == knownEntityAddresses(networkID).xrdResourceAddress.address
	}
}

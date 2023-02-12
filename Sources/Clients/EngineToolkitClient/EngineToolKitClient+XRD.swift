import ClientPrelude
import EngineToolkit

extension EngineToolkitClient {
	public func isXRD(component: ComponentAddress, on networkID: NetworkID) throws -> Bool {
		try isXRD(address: component.address, on: networkID)
	}

	private func isXRD(address: String, on networkID: NetworkID) throws -> Bool {
		try address == knownEntityAddresses(networkID).xrdResourceAddress.address
	}
}

import ClientPrelude
import EngineToolkit
import ProfileClient

public extension EngineToolkitClient {
	func isXRD(component: ComponentAddress) async throws -> Bool {
		@Dependency(\.profileClient.getCurrentNetworkID) var getCurrentNetworkID
		let networkID = await getCurrentNetworkID()

		return try isXRD(component: component, on: networkID)
	}

	func isXRD(component: ComponentAddress, on networkID: NetworkID) throws -> Bool {
		try isXRD(address: component.address, on: networkID)
	}

	private func isXRD(address: String, on networkID: NetworkID) throws -> Bool {
		try address == knownEntityAddresses(networkID).xrdResourceAddress.address
	}
}

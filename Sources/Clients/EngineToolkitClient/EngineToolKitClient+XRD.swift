import ClientPrelude
import EngineToolkit

public extension EngineToolkitClient {
	func isXRD(resource: ResourceAddress) -> Bool {
		NetworkID.allCases.contains { isXRD(address: resource.address, on: $0) }
	}
	
	func isXRD(component: ComponentAddress) -> Bool {
		NetworkID.allCases.contains { isXRD(address: component.address, on: $0) }
	}
		
	func isXRD(component: ComponentAddress, on networkID: NetworkID) -> Bool {
		isXRD(address: component.address, on: networkID)
	}
	
	private func isXRD(address: String, on networkID: NetworkID) -> Bool {
		guard let response = try? knownEntityAddresses(networkID) else { return false }
		return address == response.xrdResourceAddress.address
	}
}

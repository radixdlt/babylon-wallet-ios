import Foundation
import Sargon

extension Profile {
	mutating func changeCurrentToMainnetIfNeeded() {
		appPreferences.changeCurrentToMainnetIfNeeded()
	}

	mutating func addNewGateway(_ newGateway: Gateway) throws {
		appPreferences.gateways.add(newGateway)
	}

	mutating func removeGateway(_ gateway: Gateway) throws {
		appPreferences.gateways.remove(gateway)
	}

	/// Requires the presence of an `ProfileNetwork` in `networks` for
	/// `newGateway.network.id`, otherwise an error is thrown.
	mutating func changeGateway(to newGateway: Gateway) throws {
		let newNetworkID = newGateway.network.id
		// Ensure we have accounts on network, else do not change
		_ = try network(id: newNetworkID)
		try appPreferences.gateways.changeCurrent(to: newGateway)
	}

	mutating func updateDisplayAppPreferences(_ display: AppDisplay) {
		self.appPreferences.updateDisplay(display)
	}
}

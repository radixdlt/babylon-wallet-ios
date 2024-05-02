import Foundation
import Sargon

extension Profile {
	public mutating func changeCurrentToMainnetIfNeeded() {
		appPreferences.changeCurrentToMainnetIfNeeded()
	}

	public mutating func addNewGateway(_ newGateway: Gateway) throws {
		appPreferences.gateways.add(newGateway)
	}

	public mutating func removeGateway(_ gateway: Gateway) throws {
		appPreferences.gateways.remove(gateway)
	}

	/// Requires the presence of an `ProfileNetwork` in `networks` for
	/// `newGateway.network.id`, otherwise an error is thrown.
	public mutating func changeGateway(to newGateway: Gateway) throws {
		let newNetworkID = newGateway.network.id
		// Ensure we have accounts on network, else do not change
		_ = try network(id: newNetworkID)
		try appPreferences.gateways.changeCurrent(to: newGateway)
	}

	public mutating func updateDisplayAppPreferences(_ display: AppDisplay) {
		self.appPreferences.updateDisplay(display)
	}

	/// Appends a new `P2PLink` to the Profile's `AppPreferences`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PLink(_ p2pLink: P2PLink) -> P2PLink? {
		self.appPreferences.appendP2PLink(p2pLink)
	}
}

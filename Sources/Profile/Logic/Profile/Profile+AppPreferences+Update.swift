import Prelude
import RadixConnectModels

extension AppPreferences {
	public mutating func updateDisplay(_ display: Display) {
		self.display = display
	}
}

extension Profile {
	public mutating func updateDisplayAppPreferences(_ display: AppPreferences.Display) {
		self.appPreferences.updateDisplay(display)
	}
}

extension Profile {
	/// Appends a new `P2PClient` to the Profile's `AppPreferences`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PClient(_ p2pClient: P2PClient) -> P2PClient? {
		self.appPreferences.appendP2PClient(p2pClient)
	}
}

extension AppPreferences {
	/// Appends a new `P2PClient`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PClient(_ p2pClient: P2PClient) -> P2PClient? {
		self.p2pClients.append(p2pClient)
	}
}

extension P2PClients {
	/// Appends a new `P2PClient`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	internal mutating func append(_ client: P2PClient) -> P2PClient? {
		guard !clients.contains(where: { client.id == $0.id }) else {
			return nil
		}
		let (inserted, _) = clients.append(client)
		assert(inserted)
		return client
	}
}

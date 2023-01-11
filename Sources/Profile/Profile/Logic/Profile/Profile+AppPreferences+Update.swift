import Foundation
import P2PModels

public extension AppPreferences {
	mutating func updateDisplay(_ display: Display) {
		self.display = display
	}
}

public extension Profile {
	mutating func updateDisplayAppPreferences(_ display: AppPreferences.Display) {
		self.appPreferences.updateDisplay(display)
	}
}

public extension Profile {
	/// Appends a new `P2PClient` to the Profile's `AppPreferences`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func appendP2PClient(_ p2pClient: P2PClient) -> P2PClient? {
		self.appPreferences.appendP2PClient(p2pClient)
	}
}

internal extension AppPreferences {
	/// Appends a new `P2PClient`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func appendP2PClient(_ p2pClient: P2PClient) -> P2PClient? {
		self.p2pClients.append(p2pClient)
	}
}

internal extension P2PClients {
	/// Appends a new `P2PClient`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func append(_ client: P2PClient) -> P2PClient? {
		guard !clients.contains(where: { client.id == $0.id }) else {
			return nil
		}
		let (inserted, _) = clients.append(client)
		assert(inserted)
		return client
	}
}

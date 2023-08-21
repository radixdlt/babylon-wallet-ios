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
	/// Appends a new `P2PLink` to the Profile's `AppPreferences`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PLink(_ p2pLinks: P2PLink) -> P2PLink? {
		self.appPreferences.appendP2PLink(p2pLinks)
	}
}

extension AppPreferences {
	/// Appends a new `P2PLink`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PLink(_ p2pLinks: P2PLink) -> P2PLink? {
		self.p2pLinks.append(p2pLinks)
	}
}

extension P2PLinks {
	/// Appends a new `P2PLink`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	mutating func append(_ link: P2PLink) -> P2PLink? {
		guard !links.contains(where: { link.id == $0.id }) else {
			return nil
		}
		let (inserted, _) = links.append(link)
		assert(inserted)
		return link
	}
}

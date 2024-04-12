import Sargon

extension AppPreferences {
	public mutating func updateDisplay(_ display: AppDisplay) {
		self.display = display
	}
}

extension Profile {
	public mutating func updateDisplayAppPreferences(_ display: AppDisplay) {
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

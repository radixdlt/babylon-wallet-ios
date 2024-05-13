import Foundation
import Sargon

extension AppPreferences {
	public mutating func updateDisplay(_ display: AppDisplay) {
		self.display = display
	}
}

extension AppPreferences {
	public mutating func changeCurrentToMainnetIfNeeded() {
		gateways.changeCurrentToMainnetIfNeeded()
	}

	/// Appends a new `P2PLink`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PLink(_ p2pLink: P2PLink) -> P2PLink? {
		var identifiedP2PLinks = p2pLinks.asIdentified()
		let appended = identifiedP2PLinks.appendP2PLink(p2pLink)
		p2pLinks = identifiedP2PLinks.elements
		return appended
	}
}

extension P2PLinks {
	/// Appends a new `P2PLink`, returns `nil` if it was not inserted (because already present).
	@discardableResult
	public mutating func appendP2PLink(_ link: P2PLink) -> P2PLink? {
		guard !contains(link) else {
			return nil
		}
		append(link)
		assert(contains(link))
		return link
	}
}

extension AppPreferences {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"transaction": transaction,
				"security": security,
				"display": display,
				"p2pLinks": p2pLinks,
				"gateways": gateways,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		transaction: \(transaction),
		security: \(security),
		display: \(display),
		p2pLinks: \(p2pLinks),
		gateways: \(gateways)
		"""
	}
}

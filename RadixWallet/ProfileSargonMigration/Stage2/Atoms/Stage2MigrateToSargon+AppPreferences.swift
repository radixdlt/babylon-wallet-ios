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
	public mutating func appendP2PLink(_ p2pLinks: P2PLink) -> P2PLink? {
		sargonProfileFinishMigrateAtEndOfStage1()
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

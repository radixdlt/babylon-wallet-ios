// MARK: - AppPreferences
/// Security structure, connected P2P clients, and display settings.
public struct AppPreferences:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	public var transaction: Transaction

	/// Controls e.g. if Profile Snapshot gets synced to iCloud or not.
	public var security: Security

	/// Display settings in the wallet app, such as appearences, currency etc.
	public var display: Display

	/// The active network
	public var gateways: Gateways

	public init(
		transaction: Transaction = .default,
		security: Security = .default,
		display: Display = .default,
		gateways: Gateways = .preset
	) {
		self.transaction = transaction
		self.security = security
		self.display = display
		self.gateways = gateways
	}

	public static let `default`: Self = .init()
}

extension AppPreferences {
	public mutating func changeCurrentToMainnetIfNeeded() {
		gateways.changeCurrentToMainnetIfNeeded()
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
		gateways: \(gateways)
		"""
	}
}

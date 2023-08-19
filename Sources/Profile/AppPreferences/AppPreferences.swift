import Prelude
import RadixConnectModels

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

	/// Collection of clients user have connected P2P with, typically these
	/// are WebRTC connections with DApps, but might be Android or iPhone
	/// clients as well.
	public var p2pLinks: P2PLinks

	/// The active network
	public var gateways: Gateways

	public init(
		transaction: Transaction = .default,
		security: Security = .default,
		display: Display = .default,
		p2pLinks: P2PLinks = [],
		gateways: Gateways = .init(current: .default)
	) {
		self.transaction = transaction
		self.security = security
		self.display = display
		self.p2pLinks = p2pLinks
		self.gateways = gateways
	}

	public static let `default`: Self = .init()
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

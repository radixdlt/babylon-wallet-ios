import EngineToolkitModels
import P2PModels
import Prelude

// MARK: - AppPreferences
/// Security structure, connected P2P clients, and display settings.
public struct AppPreferences:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// Controls e.g. if Profile Snapshot gets synced to iCloud or not.
	public var security: Security

	/// Display settings in the wallet app, such as appearences, currency etc.
	public var display: Display

	/// Collection of clients user have connected P2P with, typically these
	/// are WebRTC connections with DApps, but might be Android or iPhone
	/// clients as well.
	public var p2pClients: P2PClients

	/// The active network
	public var gateways: Gateways

	public init(
		security: Security = .default,
		display: Display = .default,
		p2pClients: P2PClients = [],
		gateways: Gateways = .init(current: .nebunet)
	) {
		self.security = security
		self.display = display
		self.p2pClients = p2pClients
		self.gateways = gateways
	}

	public static let `default`: Self = .init()
}

extension AppPreferences {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"security": security,
				"display": display,
				"p2pClients": p2pClients,
				"gateways": gateways,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		security: \(security),
		display: \(display),
		p2pClients: \(p2pClients),
		gateways: \(gateways)
		"""
	}
}

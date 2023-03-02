import EngineToolkitModels
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
	/// Display settings in the wallet app, such as appearences, currency etc.
	public var display: Display

	/// Collection of clients user have connected P2P with, typically these
	/// are WebRTC connections with DApps, but might be Android or iPhone
	/// clients as well.
	public var p2pClients: P2PClients

	/// The active network
	public var networkAndGateway: NetworkAndGateway

	public init(
		display: Display = .default,
		p2pClients: P2PClients = [],
		networkAndGateway: NetworkAndGateway = .nebunet
	) {
		self.display = display
		self.p2pClients = p2pClients
		self.networkAndGateway = networkAndGateway
	}

	public static let `default`: Self = .init()
}

extension AppPreferences {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"display": display,
				"p2pClients": p2pClients,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		display: \(display),
		p2pClients: \(p2pClients),
		"""
	}
}

// MARK: AppPreferences.Display
extension AppPreferences {
	/// Display settings in the wallet app, such as appearences, currency etc.
	public struct Display:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// Which fiat currency the prices are measured in, e.g. EUR.
		public var fiatCurrencyPriceTarget: FiatCurrency

		public init(fiatCurrencyPriceTarget: FiatCurrency = .usd) {
			self.fiatCurrencyPriceTarget = fiatCurrencyPriceTarget
		}
	}
}

extension AppPreferences.Display {
	public static let `default` = Self()
}

extension AppPreferences.Display {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"fiatCurrencyPriceTarget": fiatCurrencyPriceTarget,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		fiatCurrencyPriceTarget: \(fiatCurrencyPriceTarget),
		"""
	}
}

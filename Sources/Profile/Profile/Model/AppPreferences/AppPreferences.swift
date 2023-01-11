import EngineToolkit
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
		p2pClients: P2PClients,
		networkAndGateway: NetworkAndGateway = .nebunet
	) {
		self.display = display
		self.p2pClients = p2pClients
		self.networkAndGateway = networkAndGateway
	}
}

public extension AppPreferences {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"display": display,
				"p2pClients": p2pClients,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		display: \(display),
		p2pClients: \(p2pClients),
		"""
	}
}

// MARK: AppPreferences.Display
public extension AppPreferences {
	/// Display settings in the wallet app, such as appearences, currency etc.
	struct Display:
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

public extension AppPreferences.Display {
	static let `default` = Self()
}

public extension AppPreferences.Display {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"fiatCurrencyPriceTarget": fiatCurrencyPriceTarget,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		fiatCurrencyPriceTarget: \(fiatCurrencyPriceTarget),
		"""
	}
}

// MARK: - FiatCurrency
public enum FiatCurrency:
	String,
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpRepresentable
{
	case usd, eur, gbp
}

public extension FiatCurrency {
	var sign: String {
		switch self {
		case .usd:
			return "$"
		case .gbp:
			return "£"
		case .eur:
			return "€"
		}
	}

	var symbol: String {
		rawValue.uppercased()
	}
}

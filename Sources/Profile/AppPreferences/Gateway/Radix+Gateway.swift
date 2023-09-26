import Prelude

// MARK: - Radix.Gateway
extension Radix {
	public struct Gateway:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public typealias ID = URL
		public let network: Network
		/// The URL to the gateways API endpoint
		public let url: URL
		public let name: String?
		public var id: ID { url }

		public init(
			network: Network,
			url: URL,
			name: String? = nil
		) {
			self.network = network
			self.url = url
			self.name = name
		}
	}
}

extension Radix.Gateway {
	public static let `default` = Radix.Gateway.mainnet
}

extension Radix.Gateway {
	public static var mainnet: Self {
		.init(
			network: .mainnet,
			url: URL(string: "https://mainnet.radixdlt.com/")!,
			name: "Mainnet Gateway"
		)
	}

	public static var stokenet: Self {
		.init(
			network: .stokenet,
			url: URL(string: "babylon-stokenet-gateway.radixdlt.com/")!,
			name: "Stokenet (testnet) Gateway"
		)
	}

	public static var rcnet: Self {
		.init(
			network: .zabanet,
			url: URL(string: "https://rcnet-v3.radixdlt.com/")!,
			name: "RCnet v3 Gateway"
		)
	}

	public static var nebunet: Self {
		.init(
			network: .nebunet,
			url: URL(string: "https://betanet.radixdlt.com")!
		)
	}

	public static var kisharnet: Self {
		.init(
			network: .kisharnet,
			url: URL(string: "https://rcnet.radixdlt.com/")!
		)
	}

	public static var ansharnet: Self {
		.init(
			network: .ansharnet,
			url: URL(string: "https://ansharnet-gateway.radixdlt.com/")!
		)
	}

	public static var hammunet: Self {
		.init(
			network: .hammunet,
			url: URL(string: "https://hammunet-gateway.radixdlt.com")!
		)
	}

	public static var enkinet: Self {
		.init(
			network: .enkinet,
			url: URL(string: "https://enkinet-gateway.radixdlt.com")!
		)
	}

	public static var mardunet: Self {
		.init(
			network: .mardunet,
			url: URL(string: "https://mardunet-gateway.radixdlt.com")!
		)
	}

	public static var simulator: Self {
		.init(
			network: .simulator,
			url: URL(string: "https://mardunet-gateway.radixdlt.com")!
		)
	}

	private static var wellknown: [Self] { [.mainnet, .stokenet] }
}

extension Radix.Gateway {
	public var isWellknown: Bool {
		Self.wellknown.contains(self)
	}

	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"network": network,
				"url": url,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		network: \(network),
		url: \(url)
		"""
	}
}

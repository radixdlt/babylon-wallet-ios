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
		public var id: ID { url }

		public init(network: Network, url: URL) {
			self.network = network
			self.url = url
		}
	}
}

extension Radix.Gateway {
	public static let `default` = Radix.Gateway.rcnet
}

extension Radix.Gateway {
	public static var mainnet: Self {
		.init(
			network: .mainnet,
			url: URL(string: "https://mainnet.radixdlt.com/")!
		)
	}

	public static var stokenet: Self {
		.init(
			network: .stokenet,
			url: URL(string: "babylon-stokenet-gateway.radixdlt.com/")!
		)
	}

	public static var rcnet: Self {
		.init(
			network: .zabanet,
			url: URL(string: "https://rcnet-v3.radixdlt.com/")!
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
}

extension Radix.Gateway {
	public var isDefault: Bool {
		id == Self.default.id
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

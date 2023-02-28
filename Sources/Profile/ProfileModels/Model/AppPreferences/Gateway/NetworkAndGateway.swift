import Prelude

// MARK: - Gateway
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

extension Gateway {
	/// `"https://betanet.radixdlt.com"`
	/// you can also use `"https://nebunet-gateway.radixdlt.com"`
	public static var nebunet: Self {
		.init(
			network: .nebunet,
			url: URL(string: "https://betanet.radixdlt.com")!
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
}

extension Gateway {
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

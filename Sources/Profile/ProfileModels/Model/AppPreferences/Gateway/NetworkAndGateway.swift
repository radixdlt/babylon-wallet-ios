import Prelude

// MARK: - NetworkAndGateway
public struct NetworkAndGateway:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	public let network: Network
	public let gatewayAPIEndpointURL: URL

	public init(network: Network, gatewayAPIEndpointURL: URL) {
		self.network = network
		self.gatewayAPIEndpointURL = gatewayAPIEndpointURL
	}
}

extension NetworkAndGateway {
	/// `"https://betanet.radixdlt.com"`
	/// you can also use `"https://nebunet-gateway.radixdlt.com"`
	public static var nebunet: Self {
		.init(
			network: .nebunet,
			gatewayAPIEndpointURL: URL(string: "https://betanet.radixdlt.com")!
		)
	}

	public static var hammunet: Self {
		.init(
			network: .hammunet,
			gatewayAPIEndpointURL: URL(string: "https://hammunet-gateway.radixdlt.com")!
		)
	}

	public static var enkinet: Self {
		.init(
			network: .enkinet,
			gatewayAPIEndpointURL: URL(string: "https://enkinet-gateway.radixdlt.com")!
		)
	}

	public static var mardunet: Self {
		.init(
			network: .mardunet,
			gatewayAPIEndpointURL: URL(string: "https://mardunet-gateway.radixdlt.com")!
		)
	}
}

extension NetworkAndGateway {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"network": network,
				"gatewayAPIEndpointURL": gatewayAPIEndpointURL,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		network: \(network),
		gatewayAPIEndpointURL: \(gatewayAPIEndpointURL)
		"""
	}
}

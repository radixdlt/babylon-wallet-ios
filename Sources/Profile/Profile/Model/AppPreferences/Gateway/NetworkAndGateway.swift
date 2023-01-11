import CustomDump
import Foundation

// MARK: - AppPreferences.NetworkAndGateway
public extension AppPreferences {
	struct NetworkAndGateway:
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
}

public extension AppPreferences.NetworkAndGateway {
	/// `"https://betanet.radixdlt.com"`
	/// you can also use `"https://nebunet-gateway.radixdlt.com"`
	static var nebunet: Self {
		.init(
			network: .nebunet,
			gatewayAPIEndpointURL: URL(string: "https://betanet.radixdlt.com")!
		)
	}

	static var hammunet: Self {
		.init(
			network: .hammunet,
			gatewayAPIEndpointURL: URL(string: "https://hammunet-gateway.radixdlt.com")!
		)
	}

	static var enkinet: Self {
		.init(
			network: .enkinet,
			gatewayAPIEndpointURL: URL(string: "https://enkinet-gateway.radixdlt.com")!
		)
	}

	static var mardunet: Self {
		.init(
			network: .mardunet,
			gatewayAPIEndpointURL: URL(string: "https://mardunet-gateway.radixdlt.com")!
		)
	}
}

public extension AppPreferences.NetworkAndGateway {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"network": network,
				"gatewayAPIEndpointURL": gatewayAPIEndpointURL,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		network: \(network),
		gatewayAPIEndpointURL: \(gatewayAPIEndpointURL)
		"""
	}
}

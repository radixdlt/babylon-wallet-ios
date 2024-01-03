import EngineToolkit

// MARK: - Radix.Dashboard
extension Radix {
	public struct Dashboard: Sendable, Hashable, Codable, Identifiable, CustomStringConvertible {
		public typealias ID = URL

		public let url: URL
		public var id: ID { url }

		public init(url: URL) {
			self.url = url
		}
	}
}

extension Radix.Dashboard {
	public static func dashboard(forNetwork network: Radix.Network) -> Self {
		dashboard(forNetworkID: network.id)
	}

	public static func dashboard(forNetworkID network: NetworkID) -> Self {
		switch network {
		case .mainnet:
			.mainnet
		case .nebunet:
			.rcnet
		case .kisharnet:
			.kisharnet
		case .mardunet:
			.mardunet
		case .enkinet:
			.enkinet
		case .hammunet:
			.hammunet
		case .ansharnet:
			.rcnetV2
		case .zabanet:
			.rcnetV3
		case .stokenet:
			.stokenet
		default:
			// What else to default to..?
			.mainnet
		}
	}
}

extension Radix.Dashboard {
	public static var mainnet: Self {
		.init(
			url: URL(string: "https://dashboard.radixdlt.com/")!
		)
	}

	public static var rcnet: Self {
		.init(
			url: URL(string: "https://rcnet-dashboard.radixdlt.com/")!
		)
	}

	public static var rcnetV2: Self {
		.init(
			url: URL(string: "https://rcnet-v2-dashboard.radixdlt.com/")!
		)
	}

	public static var rcnetV3: Self {
		.init(
			url: URL(string: "https://rcnet-v3-dashboard.radixdlt.com/")!
		)
	}

	public static var stokenet: Self {
		.init(
			url: URL(string: "https://stokenet-dashboard.radixdlt.com/")!
		)
	}

	public static var kisharnet: Self {
		.init(
			url: URL(string: "https://kisharnet-dashboard.radixdlt.com/")!
		)
	}

	public static var mardunet: Self {
		.init(
			url: URL(string: "https://mardunet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	public static var gilganet: Self {
		.init(
			url: URL(string: "https://gilganet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	public static var enkinet: Self {
		.init(
			url: URL(string: "https://enkinet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	public static var hammunet: Self {
		.init(
			url: URL(string: "https://hammunet-dashboard.rdx-works-main.extratools.works/")!
		)
	}
}

extension Radix.Dashboard {
	public var description: String {
		"""
		url: \(url)
		"""
	}
}

extension Radix.Dashboard {
	enum Path: String {
		case account
		case recentTransactions = "recent-transactions"
	}

	func recentTransactionsURL(_ address: AccountAddress) -> URL {
		self.url
			.appending(path: .account)
			.appending(path: address.address)
			.appending(path: .recentTransactions)
	}
}

extension URL {
	fileprivate func appending(path: Radix.Dashboard.Path) -> Self {
		appending(path: path.rawValue)
	}
}

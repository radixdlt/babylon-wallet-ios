import Sargon

// MARK: - RadixDashboard
struct RadixDashboard: Sendable, Hashable, Codable, Identifiable, CustomStringConvertible {
	typealias ID = URL

	let url: URL
	var id: ID { url }

	init(url: URL) {
		self.url = url
	}
}

extension RadixDashboard {
	static func dashboard(forNetwork network: NetworkDefinition) -> Self {
		dashboard(forNetworkID: network.id)
	}

	static func dashboard(forNetworkID network: NetworkID) -> Self {
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

extension RadixDashboard {
	static var mainnet: Self {
		.init(
			url: URL(string: "https://dashboard.radixdlt.com/")!
		)
	}

	static var rcnet: Self {
		.init(
			url: URL(string: "https://rcnet-dashboard.radixdlt.com/")!
		)
	}

	static var rcnetV2: Self {
		.init(
			url: URL(string: "https://rcnet-v2-dashboard.radixdlt.com/")!
		)
	}

	static var rcnetV3: Self {
		.init(
			url: URL(string: "https://rcnet-v3-dashboard.radixdlt.com/")!
		)
	}

	static var stokenet: Self {
		.init(
			url: URL(string: "https://stokenet-dashboard.radixdlt.com/")!
		)
	}

	static var kisharnet: Self {
		.init(
			url: URL(string: "https://kisharnet-dashboard.radixdlt.com/")!
		)
	}

	static var mardunet: Self {
		.init(
			url: URL(string: "https://mardunet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	static var gilganet: Self {
		.init(
			url: URL(string: "https://gilganet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	static var enkinet: Self {
		.init(
			url: URL(string: "https://enkinet-dashboard.rdx-works-main.extratools.works/")!
		)
	}

	static var hammunet: Self {
		.init(
			url: URL(string: "https://hammunet-dashboard.rdx-works-main.extratools.works/")!
		)
	}
}

extension RadixDashboard {
	var description: String {
		"""
		url: \(url)
		"""
	}
}

extension RadixDashboard {
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
	fileprivate func appending(path: RadixDashboard.Path) -> Self {
		appending(path: path.rawValue)
	}
}

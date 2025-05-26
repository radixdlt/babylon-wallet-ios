// MARK: - DAppsDirectoryClient
public struct DAppsDirectoryClient: Sendable {
	let fetchDApps: FetchDApps
}

extension DAppsDirectoryClient {
	typealias FetchDApps = @Sendable (_ forceRefresh: Bool) async throws -> DApps
}

extension DAppsDirectoryClient {
	struct CategorizedDApps: Codable, Sendable {
		let highlighted: DApps
		let others: DApps
	}

	typealias DApps = IdentifiedArrayOf<DApp>
	struct DApp: Codable, Sendable, Hashable, Identifiable {
		var id: DappDefinitionAddress {
			address
		}

		let name: String
		let address: DappDefinitionAddress
		let tags: IdentifiedArrayOf<Tag>
	}
}

extension DAppsDirectoryClient.DApp {
	enum Tag: String, Identifiable, CaseIterable, Codable {
		case defi = "DeFi"
		case dex = "DEX"
		case token = "Token"
		case trade = "Trade"
		case marketplace = "Marketplace"
		case nfts = "NFTs"
		case lending = "Lending"
		case tools = "Tools"
		case dashboard = "Dashboard"
	}
}

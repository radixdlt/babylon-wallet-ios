// MARK: - DAppsDirectoryClient
public struct DAppsDirectoryClient: Sendable {
	let fetchDApps: FetchDApps
}

extension DAppsDirectoryClient {
	typealias FetchDApps = @Sendable () async throws -> DApps
}

extension DAppsDirectoryClient {
	typealias DApps = IdentifiedArrayOf<DApp>
	struct DApp: Sendable, Hashable, Identifiable {
		var id: DappDefinitionAddress {
			dAppDefinitionAddress
		}

		let dAppDefinitionAddress: DappDefinitionAddress
		let tags: IdentifiedArrayOf<Tag>
	}
}

extension DAppsDirectoryClient.DApp {
	enum Tag: String, Identifiable {
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

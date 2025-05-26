// MARK: - DAppsDirectoryClient + DependencyKey
extension DAppsDirectoryClient: DependencyKey {
	public typealias Value = DAppsDirectoryClient
	static let endpoint = URL(string: "https://dapps-list.radixdlt.com/list")!

	public static let liveValue = {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.cacheClient) var cacheClient

		@Sendable
		func fetchDAppsFromRemote() async throws -> CategorizedDApps {
			let request = URLRequest(url: endpoint)
			let data = try await httpClient.executeRequest(request)
			return try JSONDecoder().decode(CategorizedDApps.self, from: data)
		}

		@Sendable
		func fetchdDApps(forceRefresh: Bool) async throws -> DApps {
			try await cacheClient.withCaching(cacheEntry: .dAppsDirectory, forceRefresh: forceRefresh, request: fetchDAppsFromRemote).allDApps
		}

		return Self(fetchDApps: fetchdDApps)
	}()
}

extension DAppsDirectoryClient.CategorizedDApps {
	var allDApps: DAppsDirectoryClient.DApps {
		(highlighted.shuffled() + others.shuffled()).asIdentified()
	}
}

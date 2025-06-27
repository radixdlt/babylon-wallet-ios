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
	struct DApp: Sendable, Hashable, Identifiable {
		var id: DappDefinitionAddress {
			address
		}

		let name: String
		let address: DappDefinitionAddress
		let tags: [OnLedgerTag]
		let dAppCategory: Category
	}
}

extension DAppsDirectoryClient.DApp: Codable {
	enum Key: CodingKey {
		case name
		case address
		case tags
		case dAppCategory
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: Key.self)
		self.name = try container.decode(String.self, forKey: .name)
		self.address = try container.decode(DappDefinitionAddress.self, forKey: .address)
		self.tags = try container.decode([String].self, forKey: .tags)
			.map(\.localizedLowercase)
			.compactMap(NonEmptyString.init(rawValue:))
			.map(OnLedgerTag.init)

		self.dAppCategory = try container.decodeIfPresent(Category.self, forKey: .dAppCategory) ?? .other
	}
}

extension DAppsDirectoryClient.DApp {
	enum Category: String, CaseIterable {
		case defi
		case utility
		case dao
		case nft
		case meme

		case other
	}
}

extension DAppsDirectoryClient.DApp.Category: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawString = try container.decode(String.self)

		if let `case` = Self(rawValue: rawString.lowercased()) {
			self = `case`
		} else {
			self = .other
		}
	}
}

extension DAppsDirectoryClient.DApp.Category: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		let allCases = Self.allCases
		return allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
	}
}

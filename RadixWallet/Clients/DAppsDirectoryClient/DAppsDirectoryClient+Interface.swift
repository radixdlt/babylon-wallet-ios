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
		let tags: IdentifiedArrayOf<Tag>
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
		self.tags = try container.decode([Result<Tag, DecodingError>].self, forKey: .tags)
			.compactMap { try? $0.get() }
			.asIdentified()
		self.dAppCategory = try container.decodeIfPresent(Category.self, forKey: .dAppCategory) ?? .other
	}
}

extension DAppsDirectoryClient.DApp {
	enum Tag: String, Identifiable, CaseIterable {
		case defi
		case dex
		case token
		case trade
		case marketplace
		case nfts
		case lending
		case tools
		case dashboard
	}

	enum Category: String, CaseIterable {
		case defi
		case utility
		case dao
		case nft
		case meme

		case other
	}
}

extension DAppsDirectoryClient.DApp.Tag: Codable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawString = try container.decode(String.self)

		if let `case` = Self(rawValue: rawString.lowercased()) {
			self = `case`
		} else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Cannot initialize UserType from invalid String value \(rawString)"
			)
		}
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

extension Result: Decodable where Success: Decodable, Failure == DecodingError {
	public init(from decoder: Decoder) throws {
		do {
			let container = try decoder.singleValueContainer()
			self = try .success(container.decode(Success.self))
		} catch let err as Failure {
			self = .failure(err)
		}
	}
}

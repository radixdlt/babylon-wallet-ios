
@available(*, deprecated, renamed: "GatewayAPI.AccountLockerVaultCollectionItem")
public typealias AccountLockerVaultCollectionItem = GatewayAPI.AccountLockerVaultCollectionItem

// MARK: - GatewayAPI.AccountLockerVaultCollectionItem
extension GatewayAPI {
	public enum AccountLockerVaultCollectionItem: Codable, Hashable {
		case fungible(AccountLockerVaultCollectionItemFungible)
		case nonFungible(AccountLockerVaultCollectionItemNonFungible)

		private enum CodingKeys: String, CodingKey, CaseIterable {
			case type
		}

		public var fungible: AccountLockerVaultCollectionItemFungible? {
			if case let .fungible(wrapped) = self {
				return wrapped
			}
			return nil
		}

		public var nonFungible: AccountLockerVaultCollectionItemNonFungible? {
			if case let .nonFungible(wrapped) = self {
				return wrapped
			}
			return nil
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let type = try container.decode(AccountLockerVaultCollectionItemType.self, forKey: .type)

			switch type {
			case .fungible:
				self = try .fungible(.init(from: decoder))
			case .nonFungible:
				self = try .nonFungible(.init(from: decoder))
			}
		}

		public func encode(to encoder: Encoder) throws {
			switch self {
			case let .fungible(item):
				try item.encode(to: encoder)
			case let .nonFungible(item):
				try item.encode(to: encoder)
			}
		}
	}
}

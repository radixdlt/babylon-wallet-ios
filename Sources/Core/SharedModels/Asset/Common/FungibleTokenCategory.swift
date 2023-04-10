import Prelude

// MARK: - FungibleTokenCategory
public enum FungibleTokenCategory {
        case xrd(FungibleTokenContainer)
        case nonXrd(PaginatedResourceContainer<[FungibleTokenContainer]>)
}

extension FungibleTokenCategory {
        public var containers: [FungibleTokenContainer] {
                switch self {
                case let .xrd(container):
                        return [container]
                case let .nonXrd(container):
                        return container.loaded
                }
        }
}

extension FungibleTokenCategory: Identifiable {
        public enum CategoryType: Sendable {
                case xrd
                case nonXrd
        }

        public typealias ID = CategoryType
        public var id: ID {
                switch self {
                case .xrd:
                        return .xrd
                case .nonXrd:
                        return .nonXrd
                }
        }
}

import FeaturePrelude

extension PaginatedResourceContainer where Container == IdentifiedArrayOf<FungibleTokenContainer> {
        public func sortedIntoCategories() -> [FungibleTokenCategory] {
                var xrdContainer: FungibleTokenContainer?
                var noValueTokens = [FungibleTokenContainer]()
                var tokensWithValues = [FungibleTokenContainer]()

                forEach {
                        if $0.asset.isXRD {
                                xrdContainer = $0
                        } else if $0.worth == nil {
                                noValueTokens.append($0)
                        } else {
                                tokensWithValues.append($0)
                        }
                }

                tokensWithValues.sort { $0.worth! > $1.worth! }
                noValueTokens.sort { $0.asset.symbol ?? "" < $1.asset.symbol ?? "" }

                var result = [FungibleTokenCategory]()

                if let xrdContainer {
                        result.append(.xrd(xrdContainer)) // (type: .xrd, tokenContainers: [xrdContainer]))
                }

                let otherAssets: [FungibleTokenContainer] = tokensWithValues + noValueTokens
                result.append(.nonXrd(.init(loaded: otherAssets, totalCount: totalCount, nextPageCursor: nextPageCursor)))

                return result
        }
}

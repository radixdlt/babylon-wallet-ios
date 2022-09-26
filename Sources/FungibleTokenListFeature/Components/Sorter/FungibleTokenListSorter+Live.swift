import Asset

public extension FungibleTokenListSorter {
	static let live = Self(
		sortTokens: { tokenContainers in
			var xrdContainer: FungibleTokenContainer?
			var noValueTokens = [FungibleTokenContainer]()
			var tokensWithValues = [FungibleTokenContainer]()

			tokenContainers.forEach {
				if $0.asset == .xrd {
					xrdContainer = $0
				} else if $0.worth == nil {
					noValueTokens.append($0)
				} else {
					tokensWithValues.append($0)
				}
			}

			tokensWithValues.sort { $0.worth! > $1.worth! }
			noValueTokens.sort { $0.asset.code ?? "" < $1.asset.code ?? "" }

			var result = [FungibleTokenCategory]()

			if let xrdContainer = xrdContainer {
				result.append(FungibleTokenCategory(type: .xrd, tokenContainers: [xrdContainer]))
			}

			let otherAssets: [FungibleTokenContainer] = tokensWithValues + noValueTokens
			result.append(FungibleTokenCategory(type: .nonXrd, tokenContainers: otherAssets))

			return result
		}
	)
}

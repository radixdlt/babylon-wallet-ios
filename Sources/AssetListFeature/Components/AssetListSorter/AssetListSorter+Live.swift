import AccountWorthFetcher
import Foundation

public extension AssetListSorter {
	static let live = Self(
		sortTokens: { tokenContainers in
			var xrdContainer: TokenWorthContainer?
			var noValueTokens = [TokenWorthContainer]()
			var tokensWithValues = [TokenWorthContainer]()

			tokenContainers.forEach {
				if $0.token.code == .xrd {
					xrdContainer = $0
				} else if $0.token.value == nil {
					noValueTokens.append($0)
				} else {
					tokensWithValues.append($0)
				}
			}

			tokensWithValues.sort { $0.token.value! > $1.token.value! }
			noValueTokens.sort { $0.token.code.value < $1.token.code.value }

			var result = [[TokenWorthContainer]]()

			if let xrdContainer = xrdContainer {
				result.append([xrdContainer])
			}

			let otherAssets: [TokenWorthContainer] = tokensWithValues + noValueTokens
			result.append(otherAssets)

			return result
		}
	)
}

import Asset
import FungibleTokenListFeature
import SwiftUI

// MARK: - TokenListView
public struct TokenListView: View {
	private let sortedTokens: [FungibleTokenContainer]
	private let limit = 5

	init(containers: [FungibleTokenContainer]) {
		sortedTokens = FungibleTokenListSorter.live.sortTokens(containers).map(\.tokenContainers).flatMap { $0 }
	}
}

public extension TokenListView {
	var body: some View {
		HStack(spacing: -10) {
			if sortedTokens.count > limit {
				ForEach(sortedTokens[0 ..< limit]) { token in
					TokenView(code: token.asset.code ?? "")
				}
				TokenView(code: "+\(sortedTokens.count - limit)")
			} else {
				ForEach(sortedTokens) { token in
					TokenView(code: token.asset.code ?? "")
				}
			}
		}
	}
}

// MARK: - TokenListView_Previews
struct TokenListView_Previews: PreviewProvider {
	static var previews: some View {
		TokenListView(containers: [])
	}
}

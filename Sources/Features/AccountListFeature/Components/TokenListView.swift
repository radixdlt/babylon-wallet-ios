import FeaturePrelude

// MARK: - TokenListView
// public struct TokenListView: View {
//	private let sortedTokens: [FungibleTokenContainer]
//	private let limit = 5
//
//	init(containers: [FungibleTokenContainer]) {
//		sortedTokens = containers.sortedIntoCategories().map(\.tokenContainers).flatMap { $0 }
//	}
// }
//
// extension TokenListView {
//	public var body: some View {
//		HStack(spacing: -10) {
//			if sortedTokens.count > limit {
//				ForEach(sortedTokens[0 ..< limit]) { token in
//					TokenView(code: token.asset.symbol ?? "")
//				}
//				TokenView(code: "+\(sortedTokens.count - limit)")
//			} else {
//				ForEach(sortedTokens) { token in
//					TokenView(code: token.asset.symbol ?? "")
//				}
//			}
//		}
//	}
// }
//
// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct TokenListView_Previews: PreviewProvider {
//	static var previews: some View {
//		TokenListView(containers: [])
//	}
// }
// #endif

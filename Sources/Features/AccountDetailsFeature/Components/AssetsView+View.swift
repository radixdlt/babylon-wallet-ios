import FeaturePrelude

// MARK: - AssetsView.View
extension AssetsView {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetsView>

		public init(store: StoreOf<AssetsView>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: { $0 }
			) { viewStore in
				VStack(spacing: .large3) {
					HStack(spacing: .zero) {
						Spacer()

						ForEach(viewStore.assetKinds) { kind in
							let isSelected = viewStore.activeAssetKind == kind
							Text(kind.displayText)
								.foregroundColor(isSelected ? .app.white : .app.gray1)
								.textStyle(.body1HighImportance)
								.frame(height: .large1)
								.padding(.horizontal, .medium2)
								.background(
									isSelected
										? RoundedRectangle(cornerRadius: .medium2).fill(Color.app.gray1)
										: nil
								)
								.id(kind)
								.onTapGesture {
									viewStore.send(.view(.didSelectList(kind)))
								}
						}

						Spacer()
					}.padding([.top, .horizontal], .medium1)

					switch viewStore.activeAssetKind {
					case .tokens:
						FungibleTokenList.View(
							store: store.scope(
								state: \.fungibleTokenList,
								action: { .child(.fungibleTokenList($0)) }
							)
						)
					case .nfts:
						NonFungibleTokenList.View(
							store: store.scope(
								state: \.nonFungibleTokenList,
								action: { .child(.nonFungibleTokenList($0)) }
							)
						)
					}
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
// struct AssetsView_Preview: PreviewProvider {
//	static var previews: some View {
//		let assets: OrderedSet<AssetsView.State.AssetList> = [.fungibleTokens(.init(xrdToken: nil, nonXrdTokens: []))]
//		AssetsView.View(
//			store: .init(
//				initialState: .init(assets: .init(rawValue: assets)!),
//				reducer: AssetsView()
//			)
//		)
//	}
// }
// #endif

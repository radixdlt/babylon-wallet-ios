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
			WithViewStore(store, observe: { $0 }) { viewStore in
				VStack(spacing: .large3) {
					HStack(spacing: .zero) {
						Spacer()

						ForEach(viewStore.assets) { asset in
							let isSelected = viewStore.activeList == asset
							Text(asset.displayName)
								.foregroundColor(isSelected ? .app.white : .app.gray1)
								.textStyle(.body1HighImportance)
								.frame(height: .large1)
								.padding(.horizontal, .medium2)
								.background(
									isSelected
										? RoundedRectangle(cornerRadius: .medium2).fill(Color.app.gray1)
										: nil
								)
								.id(asset)
								.onTapGesture {
									viewStore.send(.view(.didSelectList(asset)))
								}
						}

						Spacer()
					}.padding([.top, .horizontal], .medium1)

					SwitchStore(store.scope(state: \.activeList)) {
						CaseLet(
							state: /State.AssetList.fungibleTokens,
							action: { Action.child(.fungibleTokenList($0)) },
							then: { FungibleTokenList.View(store: $0) }
						)
						CaseLet(
							state: /State.AssetList.nonFungibleTokens,
							action: { Action.child(.nonFungibleTokenList($0)) },
							then: { NonFungibleTokenList.View(store: $0) }
						)
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AssetsView_Preview: PreviewProvider {
	static var previews: some View {
		let assets: OrderedSet<AssetsView.State.AssetList> = [.fungibleTokens(.init(xrdToken: nil, nonXrdTokens: []))]
		AssetsView.View(
			store: .init(
				initialState: .init(assets: .init(rawValue: assets)!),
				reducer: AssetsView()
			)
		)
	}
}
#endif

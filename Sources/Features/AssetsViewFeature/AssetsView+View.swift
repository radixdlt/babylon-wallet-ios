import FeaturePrelude
import FungibleTokenListFeature
import NonFungibleTokenListFeature

extension AssetsView.State {
	var viewState: AssetsView.ViewState {
		.init(assetKind: kind)
	}
}

// MARK: - AssetsView.View
extension AssetsView {
	public struct ViewState: Equatable {
		let assetKind: AssetsView.State.AssetKind
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetsView>

		public init(store: StoreOf<AssetsView>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .large3) {
					selectorView(with: viewStore)
						.padding([.top, .horizontal], .medium1)

					switch viewStore.assetKind {
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

						// TODO: uncomment when ready for implementation
						/*
						 case .poolUnits:
						 Text("Pool Units")
						 case .badges:
						 Text("Badges")
						 */
					}
				}
			}
		}
	}
}

// MARK: - Private Methods
extension AssetsView.View {
	private func selectorView(with viewStore: ViewStoreOf<AssetsView>) -> some SwiftUI.View {
		HStack(spacing: .zero) {
			Spacer()

			ForEach(AssetsView.State.AssetKind.allCases) { assetKind in
				selectorButton(for: assetKind, with: viewStore) {
					viewStore.send(.listSelectorTapped(assetKind))
				}
			}

			Spacer()
		}
	}

	@ViewBuilder
	private func selectorButton(
		for assetKind: AssetsView.State.AssetKind,
		with viewStore: ViewStoreOf<AssetsView>,
		action: @escaping () -> Void
	) -> some SwiftUI.View {
		let isSelected = assetKind == viewStore.assetKind
		Text(assetKind.displayText)
			.foregroundColor(isSelected ? .app.white : .app.gray1)
			.textStyle(.body1HighImportance)
			.frame(height: .large1)
			.padding(.horizontal, .medium2)
			.background(
				isSelected
					? RoundedRectangle(cornerRadius: .medium2).fill(Color.app.gray1)
					: nil
			)
			.id(assetKind)
			.onTapGesture {
				action()
			}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AssetsView_Preview: PreviewProvider {
	static var previews: some View {
		AssetsView.View(
			store: .init(
				initialState: .init(
					fungibleTokenList: .init(sections: []),
					nonFungibleTokenList: .init(rows: [])
				),
				reducer: AssetsView()
			)
		)
	}
}
#endif

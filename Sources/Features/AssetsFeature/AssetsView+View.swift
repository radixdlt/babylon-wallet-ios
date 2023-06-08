import FeaturePrelude

// MARK: - AssetsView.View
extension AssetsView {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetsView>

		public init(store: StoreOf<AssetsView>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ScrollView {
					VStack(spacing: .medium3) {
						assetTypeSelectorView(viewStore)

						if viewStore.isLoadingResources {
							ProgressView()
								.padding(.small1)
						}

						switch viewStore.activeAssetKind {
						case .fungible:
							FungibleAssetList.View(
								store: store.scope(
									state: \.fungibleTokenList,
									action: { .child(.fungibleTokenList($0)) }
								)
							)
						case .nonFungible:
							NonFungibleAssetList.View(
								store: store.scope(
									state: \.nonFungibleTokenList,
									action: { .child(.nonFungibleTokenList($0)) }
								)
							)
						}
					}
					.padding(.bottom, .medium1)
				}
				.refreshable {
					await viewStore.send(.pullToRefreshStarted).finish()
				}
				.footer(visible: viewStore.mode.isSelection) {
					WithControlRequirements(
						viewStore.selectedAssets,
						forAction: { viewStore.send(.chooseButtonTapped($0)) },
						control: { action in
							Button(viewStore.chooseButtonTitle, action: action)
								.buttonStyle(.primaryRectangular)
						}
					)
				}
				.background {
					Color.app.gray5
						.ignoresSafeArea(edges: .bottom)
				}
				.onFirstTask { @MainActor in
					await viewStore.send(.task).finish()
				}
			}
		}

		private func assetTypeSelectorView(_ viewStore: ViewStoreOf<AssetsView>) -> some SwiftUI.View {
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
								? RoundedRectangle(cornerRadius: .medium2).fill(.app.gray1)
								: nil
						)
						.id(kind)
						.onTapGesture {
							viewStore.send(.didSelectList(kind))
						}
				}

				Spacer()
			}
			.padding([.top, .horizontal], .medium1)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct AssetsView_Preview: PreviewProvider {
	static var previews: some View {
		AssetsView.View(
			store: .init(
				initialState: .init(account: .previewValue0, fungibleTokenList: .init(), nonFungibleTokenList: .init(rows: []), mode: .normal),
				reducer: AssetsView()
			)
		)
	}
}
#endif

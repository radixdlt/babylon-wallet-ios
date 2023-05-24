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
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				if viewStore.isLoadingResources {
					ProgressView()
				}
				ScrollView {
					VStack(spacing: .medium3) {
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
					.padding(.bottom, .medium1)
				}
				.refreshable {
					await viewStore.send(.pullToRefreshStarted).finish()
				}
				.background(Color.app.gray5)
				.padding(.bottom, .medium2)
				.cornerRadius(.medium2)
				.padding(.bottom, .medium2 * -2)
				.footer(shouldShow: viewStore.mode.isSelection) {
					WithControlRequirements(viewStore.selectedItems,
					                        forAction: { viewStore.send(.chooseButtonTapped($0)) })
					{ action in
						Button("Choose", action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
			}
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
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

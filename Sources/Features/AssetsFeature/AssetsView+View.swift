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
				VStack(spacing: .zero) {
					if viewStore.mode.isSelection {
						headerView(viewStore)
					}

					if viewStore.isLoadingResources {
						ProgressView()
					}

					ScrollView {
						VStack(spacing: .medium3) {
							assetTypeSelectorView(viewStore)

							switch viewStore.activeAssetKind {
							case .tokens:
								FungibleAssetList.View(
									store: store.scope(
										state: \.fungibleTokenList,
										action: { .child(.fungibleTokenList($0)) }
									)
								)
							case .nfts:
								NonFungibleAssetList.View(
									store: store.scope(
										state: \.nonFungibleTokenList,
										action: { .child(.nonFungibleTokenList($0)) }
									)
								)
							}
						}
					}
					.refreshable {
						await viewStore.send(.pullToRefreshStarted).finish()
					}

					if viewStore.mode.isSelection {
						footerView(viewStore)
					}
				}
			}
			.background(Color.app.gray5)
			.task { @MainActor in
				await ViewStore(store.stateless).send(.view(.task)).finish()
			}
		}

		private func footerView(_ viewStore: ViewStoreOf<AssetsView>) -> some SwiftUI.View {
			VStack(spacing: 0) {
				Separator()
				WithControlRequirements(
					viewStore.selectedAssets,
					forAction: { viewStore.send(.chooseButtonTapped($0)) },
					control: { action in
						Button(viewStore.chooseButtonTitle, action: action)
							.buttonStyle(.primaryRectangular)
					}
				)
				.padding(.medium3)
			}
			.background(Color.app.background)
		}

		private func headerView(_ viewStore: ViewStoreOf<AssetsView>) -> some SwiftUI.View {
			ZStack {
				HStack {
					CloseButton {
						viewStore.send(.closeButtonTapped)
					}
					Spacer()
				}
				Text("Choose Asset(s)")
					.textStyle(.body1Header)
				Spacer()
			}
			.padding([.top, .leading], .medium1)
			.padding(.bottom, .small1)
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

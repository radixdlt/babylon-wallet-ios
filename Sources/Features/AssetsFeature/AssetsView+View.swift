import FeaturePrelude

// MARK: - AssetsView.View
extension AssetsView {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetsView>

		public init(store: StoreOf<AssetsView>) {
			UITableView.appearance().backgroundColor = UIColor.clear
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: identity, send: FeatureAction.view) { viewStore in
				List {
					assetTypeSelectorView(viewStore)
						.listRowSeparator(.hidden)
						.listRowBackground(Color.clear)
						.listRowInsets(.init())

					if viewStore.isLoadingResources {
						ProgressView()
							.padding(.small1)
					} else {
						switch viewStore.activeAssetKind {
						case .fungible:
							IfLetStore(
								store.scope(
									state: \.fungibleTokenList,
									action: { .child(.fungibleTokenList($0)) }
								),
								then: { FungibleAssetList.View(store: $0) },
								else: { EmptyAssetListView.fungibleResources }
							)
						case .nonFungible:
							IfLetStore(
								store.scope(
									state: \.nonFungibleTokenList,
									action: { .child(.nonFungibleTokenList($0)) }
								),
								then: { NonFungibleAssetList.View(store: $0) },
								else: { EmptyAssetListView.nonFungibleResources }
							)
						case .poolUnits:
							IfLetStore(
								store.scope(
									state: \.poolUnitsList,
									action: { .child(.poolUnitsList($0)) }
								),
								then: { PoolUnitsList.View(store: $0) },
								else: { EmptyAssetListView.poolUnits }
							)
						}
					}
				}
				.scrollContentBackground(.hidden)
				.listStyle(.insetGrouped)
				.padding(.top, .zero)
				.tokenRowShadow()
				.scrollIndicators(.hidden)
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
					viewStore.send(.task)
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
		}
	}
}

import ComposableArchitecture
import SwiftUI

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
			WithViewStore(store, observe: identity, send: FeatureAction.view) { viewStore in
				List {
					assetTypeSelectorView(viewStore)
						.listRowSeparator(.hidden)
						.listRowBackground(Color.clear)
						.listRowInsets(.init())

					if viewStore.isLoadingResources {
						ProgressView()
							.padding(.small1)
							.listRowSeparator(.hidden)
							.listRowBackground(Color.clear)
							.centered
					} else {
						switch viewStore.activeAssetKind {
						case .fungible:
							IfLetStore(
								store.scope(
									state: \.fungibleTokenList,
									action: \.child.fungibleTokenList
								),
								then: { FungibleAssetList.View(store: $0) },
								else: { EmptyAssetListView.fungibleResources }
							)
						case .nonFungible:
							IfLetStore(
								store.scope(
									state: \.nonFungibleTokenList,
									action: \.child.nonFungibleTokenList
								),
								then: { NonFungibleAssetList.View(store: $0) },
								else: { EmptyAssetListView.nonFungibleResources }
							)
						case .stakeUnits:
							IfLetStore(
								store.scope(
									state: \.stakeUnitList,
									action: \.child.stakeUnitList
								),
								then: { StakeUnitList.View(store: $0) },
								else: { EmptyAssetListView.stakes }
							)
						case .poolUnits:
							IfLetStore(
								store.scope(
									state: \.poolUnitsList,
									action: \.child.poolUnitsList
								),
								then: { PoolUnitsList.View(store: $0) },
								else: { EmptyAssetListView.poolUnits }
							)
						}
					}
				}
				.buttonStyle(.plain)
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
			ScrollViewReader { value in
				ScrollView(.horizontal) {
					HStack(spacing: .zero) {
//						Spacer()

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
									withAnimation {
										value.scrollTo(kind, anchor: .center)
									}
								}
						}

//						Spacer()
					}
				}
			}
		}
	}
}

extension View {
	/// The common style for rows displayed in AssetsView
	func rowStyle() -> some View {
		self
			.listRowInsets(.init())
			.listRowSeparator(.hidden)
	}
}

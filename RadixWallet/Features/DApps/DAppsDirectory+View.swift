import SwiftUI

// MARK: - DAppsDirectory.View
extension DAppsDirectory {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<DAppsDirectory>
		@FocusState private var focusedField: Bool

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					headerView()
					Separator()
					dAppsView()
				}
				.background(.primaryBackground)
				.destinations(with: store)
				.onFirstTask {
					await store.send(.view(.task)).finish()
				}
			}
		}

		@ViewBuilder
		func headerView() -> some SwiftUI.View {
			VStack {
				HStack {
					Spacer()
					Text(L10n.DappDirectory.title)
						.foregroundColor(Color.primaryText)
						.textStyle(.body1Header)
					Spacer()
				}
				.padding(.horizontal, .medium3)

				HStack {
					searchView()
					Button(asset: AssetResource.transactionHistoryFilterList) {
						store.send(.view(.filtersTapped))
					}
				}
				.padding(.horizontal, .medium3)

				if let filters = store.filterTags.asFilterItems.nilIfEmpty {
					ScrollView(.horizontal) {
						HStack {
							ForEach(filters) { filter in
								ItemFilterView(filter: filter, action: { _ in }, crossAction: { tag in
									store.send(.view(.filterRemoved(tag)))
								})
							}

							Spacer(minLength: 0)
						}
						.padding(.horizontal, .medium3)
					}
					.scrollIndicators(.hidden)
				}
			}
			.padding(.top, .small3)
			.padding(.bottom, .small1)
			.background(.primaryBackground)
		}

		@ViewBuilder
		func dAppsView() -> some SwiftUI.View {
			ScrollView {
				VStack(spacing: .medium1) {
					loadable(
						store.displayedDApps,
						loadingView: loadingView,
						errorView: failedView,
						successContent: loadedView
					)
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium1)
				.frame(maxWidth: .infinity)
			}
			.background(.secondaryBackground)
			.refreshable {
				store.send(.view(.pullToRefreshStarted))
			}
		}

		@ViewBuilder
		func loadingView() -> some SwiftUI.View {
			ForEach(0 ..< 10) { _ in
				Card {
					VStack(alignment: .leading, spacing: .zero) {
						PlainListRow(
							context: .dappAndPersona,
							title: "placeholder",
							subtitle: "placeholder placeholder placeholder placeholder placeholder placeholder placeholder",
							accessory: nil,
							icon: {
								Thumbnail(.dapp, url: nil)
							}
						)
						.redacted(reason: .placeholder)
						.shimmer(active: true, config: .accountResourcesLoading)
					}
				}
			}
		}

		@ViewBuilder
		func loadedView(dAppsCategories: DAppsDirectory.State.DAppsCategories) -> some SwiftUI.View {
			ForEach(dAppsCategories) { dAppCategory in
				Section {
					VStack(spacing: .small1) {
						ForEach(dAppCategory.dApps) { dApp in
							Card {
								store.send(.view(.didSelectDapp(dApp.id)))
							} contents: {
								VStack(alignment: .leading, spacing: .zero) {
									PlainListRow(
										context: .dappAndPersona,
										title: dApp.name,
										subtitle: dApp.description,
										icon: {
											Thumbnail(.dapp, url: dApp.thumbnail)
										}
									)
								}
							}
						}
					}
				} header: {
					Text("\(dAppCategory.category.title)").textStyle(.sectionHeader)
						.flushedLeft
				}
			}
		}

		@ViewBuilder
		func failedView(err: Error) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Image(systemName: "arrow.clockwise")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(.small)

				Text(L10n.DappDirectory.Error.heading)
					.foregroundStyle(.primaryText)
					.textStyle(.body1Header)
					.padding(.top, .medium3)
				Text(L10n.DappDirectory.Error.message)
					.foregroundStyle(.secondaryText)
					.textStyle(.body1HighImportance)
					.padding(.top, .small3)
			}
			.padding(.top, .huge1)
			.frame(maxWidth: .infinity)
		}

		private func searchView() -> some SwiftUI.View {
			AppTextField(
				placeholder: L10n.DappDirectory.Search.placeholder,
				text: $store.searchTerm.sending(\.view.searchTermChanged),
				focus: .on(
					true,
					binding: $store.searchBarFocused.sending(\.view.focusChanged),
					to: $focusedField
				),
				showClearButton: true,
				innerAccessory: {
					Image(systemName: "magnifyingglass")
				}
			)
			.autocorrectionDisabled()
			.keyboardType(.alphabet)
			.disabled(!store.dApps.isSuccess)
		}
	}
}

private extension StoreOf<DAppsDirectory> {
	var destination: PresentationStoreOf<DAppsDirectory.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DAppsDirectory>) -> some View {
		let destinationStore = store.destination
		return
			navigationDestination(store: destinationStore.scope(state: \.presentedDapp, action: \.presentedDapp)) {
				DappDetails.View(store: $0)
			}
			.sheet(store: destinationStore.scope(state: \.tagSelection, action: \.tagSelection)) {
				DAppTagsSelection.View(store: $0)
			}
	}
}

extension DAppsDirectoryClient.DApp.Category {
	var title: String {
		switch self {
		case .defi:
			"DeFi"
		case .dao:
			"DAO"
		case .utility:
			"Utility"
		case .meme:
			"Meme"
		case .nft:
			"NFT"
		case .other:
			"Other"
		}
	}
}

extension DAppsDirectoryClient.DApp.Tag {
	var title: String {
		switch self {
		case .defi:
			"DeFi"
		case .dex:
			"DEX"
		case .token:
			"Token"
		case .trade:
			"Trade"
		case .marketplace:
			"Marketplace"
		case .nfts:
			"NFTs"
		case .lending:
			"Lending"
		case .tools:
			"Tools"
		case .dashboard:
			"Dashboard"
		}
	}
}

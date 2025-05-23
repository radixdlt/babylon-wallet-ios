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
					Text("dApp Directory")
						.foregroundColor(Color.primaryText)
						.textStyle(.body1Header)
					Spacer()
					Button(asset: AssetResource.transactionHistoryFilterList) {
						store.send(.view(.filtersTapped))
					}
				}
				.padding(.horizontal, .medium3)

				searchView()
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
				VStack(spacing: .small1) {
					loadable(
						store.displayedDApps,
						loadingView: loadingView,
						errorView: failedView,
						successContent: loadedView
					)
				}
				.padding(.horizontal, .medium3)
				.padding(.vertical, .medium1)
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
		func loadedView(dApps: DAppsDirectory.State.DApps) -> some SwiftUI.View {
			ForEach(dApps) { dApp in
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

		@ViewBuilder
		func failedView(err: Error) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Image(systemName: "arrow.clockwise")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(.small)

				Text("Failed to load dApps.")
					.foregroundStyle(.primaryText)
					.textStyle(.body1Header)
					.padding(.top, .medium3)
				Text("Pull to refresh")
					.foregroundStyle(.secondaryText)
					.textStyle(.body1HighImportance)
					.padding(.top, .small3)
			}
			.padding(.top, .huge1)
			.frame(maxWidth: .infinity)
		}

		private func searchView() -> some SwiftUI.View {
			AppTextField(
				placeholder: "Search for dApp",
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

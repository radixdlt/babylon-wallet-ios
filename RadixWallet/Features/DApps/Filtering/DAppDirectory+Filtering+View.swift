import SwiftUI

// MARK: - DAppsFiltering.View
extension DAppsFiltering {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<DAppsFiltering>
		@FocusState private var focusedField: Bool

		var body: some SwiftUI.View {
			WithPerceptionTracking {
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
			.destinations(with: store)
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
		}
	}
}

private extension StoreOf<DAppsFiltering> {
	var destination: PresentationStoreOf<DAppsFiltering.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DAppsFiltering>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.tagSelection, action: \.tagSelection)) {
			DAppTagsSelection.View(store: $0)
		}
	}
}

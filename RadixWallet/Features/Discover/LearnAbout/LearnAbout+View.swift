import SwiftUI

// MARK: - Discover.LearnAbout.View
extension Discover.LearnAbout {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<Discover.LearnAbout>
		@FocusState private var focusedField: Bool

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .zero) {
					headerView()
					Separator()
					learnItemsView()
				}
				.radixToolbar(title: "Learn About")
				.background(.primaryBackground)
			}
		}
	}
}

extension Discover.LearnAbout.View {
	@ViewBuilder
	func learnItemsView() -> some SwiftUI.View {
		ScrollView {
			VStack(spacing: .small1) {
				ForEach(store.learnItems) { item in
					Card(action: {
						store.send(.view(.learnItemTapped(item)))
					}) {
						PlainListRow(
							title: item.title,
							subtitle: item.description,
							accessory: nil,
						) {
							Image(item.icon)
								.resizable()
								.scaledToFit()
								.frame(.small)
						}
					}
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.vertical, .medium1)
			.frame(maxWidth: .infinity)
		}
		.background(.secondaryBackground)
	}

	@ViewBuilder
	func headerView() -> some SwiftUI.View {
		searchView()
			.padding(.horizontal, .medium3)
			.padding(.vertical, .small1)
			.background(.primaryBackground)
	}

	private func searchView() -> some SwiftUI.View {
		AppTextField(
			placeholder: "Search...",
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

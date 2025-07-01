import SwiftUI

// MARK: - DAppTagsSelection.View
extension DAppTagsSelection {
	struct View: SwiftUI.View {
		let store: StoreOf<DAppTagsSelection>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				NavigationStack {
					ScrollView {
						FlowLayout {
							ItemFilterPickerView(filters: store.filterItems) { tag in
								store.send(.view(.tagSelected(tag)))
							}
						}
						.padding(.medium1)
					}
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							CloseButton {
								store.send(.view(.closeTapped))
							}
						}
						ToolbarItem(placement: .topBarTrailing) {
							Button(L10n.TransactionHistory.Filters.clearAll) {
								store.send(.view(.clearAllTapped))
							}
							.buttonStyle(.blueText)
						}
					}
					.footer {
						Button(L10n.Common.confirm, action: {
							store.send(.view(.confirmTapped))
						})
						.buttonStyle(.primaryRectangular)
					}
					.radixToolbar(title: L10n.DappDirectory.Filters.title, alwaysVisible: false)
				}
			}
		}
	}
}

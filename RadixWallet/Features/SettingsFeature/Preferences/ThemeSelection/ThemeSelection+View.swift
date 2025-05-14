import SwiftUI

// MARK: - ThemeSelection.View
extension ThemeSelection {
	struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ThemeSelection>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				Picker(
					L10n.AccountSettings.SpecificAssetsDeposits.resourceListPicker,
					selection: $store.appTheme.sending(\.view.themeChanged)
				) {
					ForEach(AppTheme.allCases, id: \.self) {
						Text($0.text)
					}
				}
				.pickerStyle(.segmented)
				.padding(.horizontal, .small3)

				// TODO: implement
				Text("Implement: ThemeSelection")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}

extension AppTheme {
	var text: String {
		switch self {
		case .light:
			"Light"
		case .dark:
			"Dark"
		case .system:
			"System"
		}
	}
}

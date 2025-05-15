import SwiftUI

// MARK: - ThemeSelection.View
extension ThemeSelection {
	struct View: SwiftUI.View {
		@Environment(\.colorScheme) var colorScheme
		@Perception.Bindable var store: StoreOf<ThemeSelection>

		var body: some SwiftUI.View {
			ZStack {
				Color.secondaryBackground.ignoresSafeArea()
				VStack(alignment: .leading) {
					Spacer()
					ForEach(AppTheme.allCases, id: \.self) { variant in
						WithPerceptionTracking {
							Card {
								store.send(.view(.themeChanged(variant)))
							} contents: {
								HStack {
									Image(systemName: variant.imageName)
									Text(variant.text)
									Spacer()
									RadioButton(
										appearance: colorScheme == .dark ? .light : .dark,
										isSelected: variant == store.appTheme
									)
								}
								.padding(.medium1)
							}
						}
					}
					Spacer()
				}
				.padding(.medium1)
				.navigationTitle(L10n.Preferences.ThemeSelection.title)
			}
			.withNavigationBar {
				store.send(.view(.closeButtonTapped))
			}
			.presentationDetents([.fraction(0.6)])
			.presentationBackground(.blur)
			.onAppear {
				store.send(.view(.appeared))
			}
		}
	}
}

extension AppTheme {
	var text: String {
		switch self {
		case .light:
			L10n.Preferences.ThemeSelection.light
		case .dark:
			L10n.Preferences.ThemeSelection.dark
		case .system:
			L10n.Preferences.ThemeSelection.system
		}
	}

	var imageName: String {
		switch self {
		case .light:
			"sun.max"
		case .dark:
			"moon"
		case .system:
			"swirl.circle.righthalf.filled"
		}
	}
}

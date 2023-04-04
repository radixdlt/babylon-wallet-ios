import FeaturePrelude

extension GeneralSettings.State {
	var viewState: GeneralSettings.ViewState {
		.init(
			iCloudProfileSyncEnabled: preferences?.security.iCloudProfileSyncEnabled ?? .default,
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? .default
		)
	}
}

// MARK: - GeneralSettings.View
extension GeneralSettings {
	public struct ViewState: Equatable {
		let iCloudProfileSyncEnabled: AppPreferences.Security.IsIcloudProfileSyncEnabled
		let isDeveloperModeEnabled: AppPreferences.Security.IsDeveloperModeEnabled
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<GeneralSettings>

		public init(store: StoreOf<GeneralSettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					coreView(with: viewStore)
						.navigationTitle(L10n.GeneralSettings.title)
						.onAppear { viewStore.send(.appeared) }
				}
			}
		}

		private func coreView(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				VStack(spacing: .zero) {
					isIcloudProfileSyncEnabled(with: viewStore)
					isDeveloperModeEnabled(with: viewStore)
					Separator()
				}
				.padding(.medium3)
			}
		}

		private func isIcloudProfileSyncEnabled(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			toggle(
				title: "Sync Wallet Data to iCloud",
				subtitle: "Warning: If disabled you might lose access to accounts/personas.",
				binding: viewStore.binding(
					get: \.iCloudProfileSyncEnabled.rawValue,
					send: { .isIcloudProfileSyncEnabledToggled(.init($0)) }
				)
			)
		}

		private func isDeveloperModeEnabled(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			toggle(
				title: L10n.GeneralSettings.DeveloperMode.title,
				subtitle: L10n.GeneralSettings.DeveloperMode.subtitle,
				binding: viewStore.binding(
					get: \.isDeveloperModeEnabled.rawValue,
					send: { .isDeveloperModeEnabledToggled(.init($0)) }
				)
			)
		}

		private func toggle(
			title: String,
			subtitle: String,
			binding: Binding<Bool>
		) -> some SwiftUI.View {
			Toggle(
				isOn: binding,
				label: {
					VStack(alignment: .leading, spacing: 0) {
						Text(title)
							.foregroundColor(.app.gray1)
							.textStyle(.body1HighImportance)

						Text(subtitle)
							.foregroundColor(.app.gray2)
							.textStyle(.body2Regular)
					}
				}
			)
			.frame(maxWidth: .infinity, idealHeight: .largeButtonHeight)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - GeneralSettings_Preview
struct GeneralSettings_Preview: PreviewProvider {
	static var previews: some View {
		GeneralSettings.View(
			store: .init(
				initialState: .previewValue,
				reducer: GeneralSettings()
			)
		)
	}
}

extension GeneralSettings.State {
	public static let previewValue = Self()
}
#endif

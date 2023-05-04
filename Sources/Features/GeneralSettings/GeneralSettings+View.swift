import FeaturePrelude

extension GeneralSettings.State {
	var viewState: GeneralSettings.ViewState {
		.init(
			hasAnyLedgerHardwareWalletFactorSources: hasAnyLedgerHardwareWalletFactorSources,
			useVerboseLedgerDisplayMode: (preferences?.display.ledgerHQHardwareWalletSigningDisplayMode ?? .default) == .verbose,
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? false
		)
	}
}

// MARK: - GeneralSettings.View
extension GeneralSettings {
	public struct ViewState: Equatable {
		let hasAnyLedgerHardwareWalletFactorSources: Bool

		/// only to be displayed if `hasAnyLedgerHardwareWalletFactorSources` is true
		let useVerboseLedgerDisplayMode: Bool

		let isDeveloperModeEnabled: Bool
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
					isDeveloperModeEnabled(with: viewStore)
					if viewStore.hasAnyLedgerHardwareWalletFactorSources {
						isUsingVerboseLedgerMode(with: viewStore)
					}
					Separator()
				}
				.padding(.medium3)
			}
		}

		private func isUsingVerboseLedgerMode(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			ToggleView(
				title: "Verbose Ledger transaction signing",
				subtitle: "When signing with your Ledger hardware wallet, should all instructions be displayed?",
				isOn: viewStore.binding(
					get: \.useVerboseLedgerDisplayMode,
					send: { .useVerboseModeToggled($0) }
				)
			)
		}

		private func isDeveloperModeEnabled(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			ToggleView(
				title: L10n.GeneralSettings.DeveloperMode.title,
				subtitle: L10n.GeneralSettings.DeveloperMode.subtitle,
				isOn: viewStore.binding(
					get: \.isDeveloperModeEnabled,
					send: { .developerModeToggled($0) }
				)
			)
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

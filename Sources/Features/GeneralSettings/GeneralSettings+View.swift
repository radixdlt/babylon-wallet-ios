import FeaturePrelude

extension GeneralSettings.State {
	var viewState: GeneralSettings.ViewState {
		.init(
			hasLedgerHardwareWalletFactorSources: hasLedgerHardwareWalletFactorSources,
			useVerboseLedgerDisplayMode: (preferences?.display.ledgerHQHardwareWalletSigningDisplayMode ?? .default) == .verbose,
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? false,
			isExportingLogs: exportLogs
		)
	}
}

// MARK: - GeneralSettings.View
extension GeneralSettings {
	public struct ViewState: Equatable {
		let hasLedgerHardwareWalletFactorSources: Bool

		/// only to be displayed if `hasLedgerHardwareWalletFactorSources` is true
		let useVerboseLedgerDisplayMode: Bool

		let isDeveloperModeEnabled: Bool
		let isExportingLogs: URL?
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
			.confirmationDialog(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /GeneralSettings.Destinations.State.deleteProfileConfirmationDialog,
				action: GeneralSettings.Destinations.Action.deleteProfileConfirmationDialog
			)
		}

		private func coreView(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				isDeveloperModeEnabled(with: viewStore)

				if !RuntimeInfo.isAppStoreBuild {
					exportLogs(with: viewStore)
				}

				if viewStore.hasLedgerHardwareWalletFactorSources {
					isUsingVerboseLedgerMode(with: viewStore)
				}

				resetWallet(with: viewStore)

				Separator()
			}
			.padding(.medium3)
		}

		private func isUsingVerboseLedgerMode(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			ToggleView(
				title: L10n.GeneralSettings.VerboseLedgerMode.title,
				subtitle: L10n.GeneralSettings.VerboseLedgerMode.subtitle,
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
					send: { .developerModeToggled(.init($0)) }
				)
			)
		}

		private func exportLogs(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text("Export Logs")
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					Text("Export and save debugging logs")
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.fixedSize()
				}

				Button("Export") {
					viewStore.send(.exportLogsTapped)
				}
				.buttonStyle(.secondaryRectangular)
				.flushedRight
			}
			.sheet(item:
				viewStore.binding(
					get: { $0.isExportingLogs },
					send: { _ in .exportLogsDismissed }
				)
			) { logFilePath in
				ShareView(items: [logFilePath])
			}
			.frame(height: .largeButtonHeight)
		}

		private func resetWallet(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(L10n.GeneralSettings.ResetWallet.title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					Text(L10n.GeneralSettings.ResetWallet.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.fixedSize()
				}

				Spacer(minLength: 0)

				Button(L10n.GeneralSettings.ResetWallet.buttonTitle) {
					viewStore.send(.deleteProfileAndFactorSourcesButtonTapped)
				}
				.buttonStyle(.secondaryRectangular(isDestructive: true))
			}
			.frame(height: .largeButtonHeight)
		}
	}
}

// MARK: - URL + Identifiable
extension URL: Identifiable {
	public var id: URL { self.absoluteURL }
}

// MARK: - ShareView
// TODO: This is alternative to `ShareLink`, which does not seem to work properly. Eventually we should make use of it instead of this wrapper.
struct ShareView: UIViewControllerRepresentable {
	typealias UIViewControllerType = UIActivityViewController

	let items: [Any]

	func makeUIViewController(context: Context) -> UIActivityViewController {
		UIActivityViewController(activityItems: items, applicationActivities: nil)
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

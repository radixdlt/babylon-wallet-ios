import FeaturePrelude

extension AppSettings.State {
	var viewState: AppSettings.ViewState {
		.init(
			hasLedgerHardwareWalletFactorSources: hasLedgerHardwareWalletFactorSources,
			useVerboseLedgerDisplayMode: (preferences?.display.ledgerHQHardwareWalletSigningDisplayMode ?? .default) == .verbose,
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? false,
			isExportingLogs: exportLogs
		)
	}
}

// MARK: - AppSettings.View
extension AppSettings {
	public struct ViewState: Equatable {
		let hasLedgerHardwareWalletFactorSources: Bool

		/// only to be displayed if `hasLedgerHardwareWalletFactorSources` is true
		let useVerboseLedgerDisplayMode: Bool

		let isDeveloperModeEnabled: Bool
		let isExportingLogs: URL?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AppSettings>

		public init(store: StoreOf<AppSettings>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					coreView(with: viewStore)
						.navigationTitle(L10n.AppSettings.title)
						.onAppear { viewStore.send(.appeared) }
				}
			}
			.confirmationDialog(
				store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
				state: /AppSettings.Destinations.State.deleteProfileConfirmationDialog,
				action: AppSettings.Destinations.Action.deleteProfileConfirmationDialog
			)
		}

		private func coreView(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
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

		private func isUsingVerboseLedgerMode(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
			ToggleView(
				title: L10n.AppSettings.VerboseLedgerMode.title,
				subtitle: L10n.AppSettings.VerboseLedgerMode.subtitle,
				isOn: viewStore.binding(
					get: \.useVerboseLedgerDisplayMode,
					send: { .useVerboseModeToggled($0) }
				)
			)
		}

		private func isDeveloperModeEnabled(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
			ToggleView(
				title: L10n.AppSettings.DeveloperMode.title,
				subtitle: L10n.AppSettings.DeveloperMode.subtitle,
				isOn: viewStore.binding(
					get: \.isDeveloperModeEnabled,
					send: { .developerModeToggled(.init($0)) }
				)
			)
		}

		private func exportLogs(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
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

		private func resetWallet(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(L10n.AppSettings.ResetWallet.title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					Text(L10n.AppSettings.ResetWallet.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.fixedSize()
				}

				Spacer(minLength: 0)

				Button(L10n.AppSettings.ResetWallet.buttonTitle) {
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

// MARK: - AppSettings_Preview
struct AppSettings_Preview: PreviewProvider {
	static var previews: some View {
		AppSettings.View(
			store: .init(
				initialState: .previewValue,
				reducer: AppSettings()
			)
		)
	}
}

extension AppSettings.State {
	public static let previewValue = Self()
}
#endif

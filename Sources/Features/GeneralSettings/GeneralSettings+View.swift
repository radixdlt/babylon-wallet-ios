import FeaturePrelude

extension GeneralSettings.State {
	var viewState: GeneralSettings.ViewState {
		.init(
			hasLedgerHardwareWalletFactorSources: hasLedgerHardwareWalletFactorSources,
			useVerboseLedgerDisplayMode: (preferences?.display.ledgerHQHardwareWalletSigningDisplayMode ?? .default) == .verbose,
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? false,
			isCloudProfileSyncEnabled: preferences?.security.isCloudProfileSyncEnabled ?? false,
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
		let isCloudProfileSyncEnabled: Bool

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
						.navigationTitle(L10n.AppSettings.title)
						.onAppear { viewStore.send(.appeared) }
				}
			}
		}

		private func coreView(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .zero) {
					isCloudProfileSyncEnabled(with: viewStore)
					isDeveloperModeEnabled(with: viewStore)
					if !RuntimeInfo.isAppStoreBuild {
						exportLogs(with: viewStore)
					}
					if viewStore.hasLedgerHardwareWalletFactorSources {
						isUsingVerboseLedgerMode(with: viewStore)
					}
					Separator()
				}
				.padding(.medium3)
			}
			.alert(
				store: store.scope(state: \.$alert, action: { .view(.alert($0)) }),
				state: /GeneralSettings.Alerts.State.confirmCloudSyncDisable,
				action: GeneralSettings.Alerts.Action.confirmCloudSyncDisable
			)
		}

		private func isCloudProfileSyncEnabled(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			ToggleView(
				title: "Sync Wallet Data to iCloud",
				subtitle: "Warning: If disabled you might lose access to accounts/personas.",
				isOn: viewStore.binding(
					get: \.isCloudProfileSyncEnabled,
					send: { .cloudProfileSyncToggled($0) }
				)
			)
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
				title: L10n.AppSettings.DeveloperMode.title,
				subtitle: L10n.AppSettings.DeveloperMode.subtitle,
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

					Text("Export the Wallet development logs")
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

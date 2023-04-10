import FeaturePrelude

extension GeneralSettings.State {
	var viewState: GeneralSettings.ViewState {
		.init(
			isDeveloperModeEnabled: preferences?.security.isDeveloperModeEnabled ?? false,
			isExportingLogs: exportLogs
		)
	}
}

// MARK: - GeneralSettings.View
extension GeneralSettings {
	public struct ViewState: Equatable {
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
		}

		private func coreView(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			VStack(spacing: .zero) {
				VStack(alignment: .leading, spacing: .zero) {
					developerModeRow(with: viewStore)
					exportLogs(with: viewStore)
					Separator()
				}
				.padding(.medium3)
			}
		}

		private func developerModeRow(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			HStack {
				VStack(alignment: .leading, spacing: 0) {
					Text(L10n.GeneralSettings.DeveloperMode.title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1HighImportance)

					Text(L10n.GeneralSettings.DeveloperMode.subtitle)
						.foregroundColor(.app.gray2)
						.textStyle(.body2Regular)
						.fixedSize()
				}

				let isDeveloperModeBinding = viewStore.binding(
					get: \.isDeveloperModeEnabled,
					send: { .developerModeToggled($0) }
				)
				Toggle(
					isOn: isDeveloperModeBinding,
					label: {}
				)
				.flushedRight
			}
			.frame(height: .largeButtonHeight)
		}

		private func exportLogs(with viewStore: ViewStoreOf<GeneralSettings>) -> some SwiftUI.View {
			Button("Export logs") {
				viewStore.send(.exportLogsTapped)
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

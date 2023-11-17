import ComposableArchitecture
import SwiftUI
extension AppSettings.State {
	var viewState: AppSettings.ViewState {
		let isDeveloperModeEnabled = preferences?.security.isDeveloperModeEnabled ?? false
		#if DEBUG
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled,
			isExportingLogs: exportLogs
		)
		#else
		return .init(
			isDeveloperModeEnabled: isDeveloperModeEnabled
		)
		#endif // DEBUG
	}
}

// MARK: - AppSettings.View
extension AppSettings {
	public struct ViewState: Equatable {
		let isDeveloperModeEnabled: Bool
		#if DEBUG
		let isExportingLogs: URL?
		init(isDeveloperModeEnabled: Bool, isExportingLogs: URL?) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
			self.isExportingLogs = isExportingLogs
		}
		#else
		init(isDeveloperModeEnabled: Bool) {
			self.isDeveloperModeEnabled = isDeveloperModeEnabled
		}
		#endif // DEBUG
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
					VStack(spacing: .zero) {
						VStack(spacing: .zero) {
							ForEach(rows) { row in
								SettingsRow(row: row) {
									viewStore.send(row.action)
								}
							}
						}

						VStack(spacing: .zero) {
							isDeveloperModeEnabled(with: viewStore)
								.withSeparator

							#if DEBUG
							exportLogs(with: viewStore)
								.withSeparator
							#endif
						}
						.padding(.horizontal, .medium3)
					}
					.navigationTitle(L10n.AppSettings.title)
					.onAppear { viewStore.send(.appeared) }
				}
			}
			.destinations(with: store)
		}

		private var rows: [SettingsRowModel<AppSettings>] {
			[
				.init(
					title: L10n.Settings.linkedConnectors,
					icon: .asset(AssetResource.desktopConnections),
					action: .manageP2PLinksButtonTapped
				),
				.init(
					title: L10n.Settings.gateways,
					icon: .asset(AssetResource.gateway),
					action: .gatewaysButtonTapped
				),
				.init(
					title: L10n.Settings.backups,
					subtitle: nil, // TODO: Determine, if possible, the date of last backup.
					icon: .asset(AssetResource.backups),
					action: .profileBackupSettingsButtonTapped
				),
				.init(
					title: L10n.AppSettings.EntityHiding.title,
					subtitle: L10n.AppSettings.EntityHiding.subtitle,
					icon: .asset(AssetResource.entityHiding),
					action: .accountAndPersonaHidingButtonTapped
				),
			]
		}

		private func isDeveloperModeEnabled(with viewStore: ViewStoreOf<AppSettings>) -> some SwiftUI.View {
			ToggleView(
				icon: AssetResource.developerMode,
				title: L10n.AppSettings.DeveloperMode.title,
				subtitle: L10n.AppSettings.DeveloperMode.subtitle,
				isOn: viewStore.binding(
					get: \.isDeveloperModeEnabled,
					send: { .developerModeToggled(.init($0)) }
				)
			)
		}

		#if DEBUG
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
			.sheet(item: viewStore.binding(get: \.isExportingLogs, send: { _ in .exportLogsDismissed })) { logFilePath in
				ShareView(items: [logFilePath])
			}
			.frame(height: .largeButtonHeight)
		}
		#endif
	}
}

private extension StoreOf<AppSettings> {
	var destination: PresentationStoreOf<AppSettings.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<AppSettings>) -> some View {
		let destinationStore = store.destination
		return manageP2PLinks(with: destinationStore)
			.gatewaySettings(with: destinationStore)
			.profileBackupSettings(with: destinationStore)
			.accountAndPersonasHiding(with: destinationStore)
	}

	private func manageP2PLinks(with destinationStore: PresentationStoreOf<AppSettings.Destination_>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destination_.State.manageP2PLinks,
			action: AppSettings.Destination_.Action.manageP2PLinks,
			destination: { P2PLinksFeature.View(store: $0) }
		)
	}

	private func gatewaySettings(with destinationStore: PresentationStoreOf<AppSettings.Destination_>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destination_.State.gatewaySettings,
			action: AppSettings.Destination_.Action.gatewaySettings,
			destination: { GatewaySettings.View(store: $0) }
		)
	}

	private func profileBackupSettings(with destinationStore: PresentationStoreOf<AppSettings.Destination_>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destination_.State.profileBackupSettings,
			action: AppSettings.Destination_.Action.profileBackupSettings,
			destination: { ProfileBackupSettings.View(store: $0) }
		)
	}

	private func accountAndPersonasHiding(with destinationStore: PresentationStoreOf<AppSettings.Destination_>) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /AppSettings.Destination_.State.accountAndPersonasHiding,
			action: AppSettings.Destination_.Action.accountAndPersonasHiding,
			destination: { AccountAndPersonaHiding.View(store: $0) }
		)
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
import ComposableArchitecture
import SwiftUI

// MARK: - AppSettings_Preview
struct AppSettings_Preview: PreviewProvider {
	static var previews: some View {
		AppSettings.View(
			store: .init(
				initialState: .previewValue,
				reducer: AppSettings.init
			)
		)
	}
}

extension AppSettings.State {
	public static let previewValue = Self()
}
#endif

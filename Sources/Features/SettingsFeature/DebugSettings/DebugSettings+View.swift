#if DEBUG
import DebugInspectProfileFeature
import EngineKit
import FeaturePrelude
import RadixConnectModels // read signaling client url
import SecureStorageClient
import SecurityStructureConfigurationListFeature

// MARK: - DebugSettings.View
extension DebugSettings {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension DebugSettings.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
			ScrollView {
				ForEach(rows) { row in
					PlainListRow(row.icon, title: row.title, subtitle: row.subtitle)
						.tappable {
							viewStore.send(row.action)
						}
						.withSeparator
				}
			}
			.padding(.bottom, .large3)
			.navigationTitle("Debug Settings") // FIXME: Strings - L10n.Settings.DebugSettings.title
			#if os(iOS)
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
			#endif
				.factorSources(with: destinationStore)
				.debugInspectProfile(with: destinationStore)
				.securityStructureConfigs(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}

	@MainActor
	private var rows: [SettingsRowModel<DebugSettings>] {
		[
			.init(
				title: L10n.Settings.multiFactor,
				icon: .systemImage("lock.square.stack.fill"),
				action: .securityStructureConfigsButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Factor sources",
				icon: .systemImage("person.badge.key"),
				action: .factorSourcesButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Inspect profile",
				icon: .systemImage("wallet.pass"),
				action: .debugInspectProfileButtonTapped
			),
		]
	}
}

// MARK: - Extensions

private extension View {
	@MainActor
	func factorSources(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.debugManageFactorSources,
			action: DebugSettings.Destinations.Action.debugManageFactorSources,
			destination: { ManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	func debugInspectProfile(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.debugInspectProfile,
			action: DebugSettings.Destinations.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}

	@MainActor
	func securityStructureConfigs(
		with destinationStore: PresentationStoreOf<DebugSettings.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettings.Destinations.State.securityStructureConfigs,
			action: DebugSettings.Destinations.Action.securityStructureConfigs,
			destination: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
		)
	}
}
#endif

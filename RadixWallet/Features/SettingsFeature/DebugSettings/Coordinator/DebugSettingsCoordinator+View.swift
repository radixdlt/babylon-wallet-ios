import ComposableArchitecture
import SwiftUI

// MARK: - DebugSettingsCoordinator.View
extension DebugSettingsCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

extension DebugSettingsCoordinator.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
			ScrollView {
				VStack(spacing: .zero) {
					ForEach(rows) { row in
						SettingsRow(row: row) {
							viewStore.send(row.action)
						}
					}
				}
			}
			.padding(.bottom, .large3)
			.navigationTitle("Debug Settings")
			.navigationBarTitleColor(.app.gray1)
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarInlineTitleFont(.app.secondaryHeader)
			.factorSources(with: destinationStore)
			.debugUserDefaultsContents(with: destinationStore)
			#if DEBUG
				.debugKeychainTest(with: destinationStore)
				.debugKeychainContents(with: destinationStore)
			#endif // DEBUG
				.debugInspectProfile(with: destinationStore)
				.securityStructureConfigs(with: destinationStore)
				.tint(.app.gray1)
				.foregroundColor(.app.gray1)
		}
		.presentsLoadingViewOverlay()
	}

	@MainActor
	private var rows: [SettingsRowModel<DebugSettingsCoordinator>] {
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
			// ONLY DEBUG EVER
			.init(
				title: "UserDefaults content",
				icon: .systemImage("person.text.rectangle"),
				action: .debugUserDefaultsContentsButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Keychain Test",
				icon: .systemImage("key"),
				action: .debugTestKeychainButtonTapped
			),
			// ONLY DEBUG EVER
			.init(
				title: "Keychain Contents",
				icon: .systemImage("key"),
				action: .debugKeychainContentsButtonTapped
			),
		]
	}
}

// MARK: - Extensions

private extension View {
	@MainActor
	func debugUserDefaultsContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.debugUserDefaultsContents,
			action: DebugSettingsCoordinator.Destinations.Action.debugUserDefaultsContents,
			destination: { DebugUserDefaultsContents.View(store: $0) }
		)
	}

	#if DEBUG
	@MainActor
	func debugKeychainTest(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.debugKeychainTest,
			action: DebugSettingsCoordinator.Destinations.Action.debugKeychainTest,
			destination: { DebugKeychainTest.View(store: $0) }
		)
	}

	@MainActor
	func debugKeychainContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.debugKeychainContents,
			action: DebugSettingsCoordinator.Destinations.Action.debugKeychainContents,
			destination: { DebugKeychainContents.View(store: $0) }
		)
	}
	#endif // DEBUG

	@MainActor
	func factorSources(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.debugManageFactorSources,
			action: DebugSettingsCoordinator.Destinations.Action.debugManageFactorSources,
			destination: { DebugManageFactorSources.View(store: $0) }
		)
	}

	@MainActor
	func debugInspectProfile(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.debugInspectProfile,
			action: DebugSettingsCoordinator.Destinations.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}

	@MainActor
	func securityStructureConfigs(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destinations>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destinations.State.securityStructureConfigs,
			action: DebugSettingsCoordinator.Destinations.Action.securityStructureConfigs,
			destination: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
		)
	}
}

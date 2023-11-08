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
			.destinations(with: store.destination)
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
		]
	}
}

// MARK: - Extensions

private extension StoreOf<DebugSettingsCoordinator> {
	var destination: PresentationStoreOf<DebugSettingsCoordinator.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}
}

@MainActor
private extension View {
	func destinations(
		with store: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		factorSources(with: store)
			.debugUserDefaultsContents(with: store)
		#if DEBUG
			.debugKeychainTest(with: store)
		#endif
			.debugInspectProfile(with: store)
			.securityStructureConfigs(with: store)
	}

	private func debugUserDefaultsContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.debugUserDefaultsContents,
			action: DebugSettingsCoordinator.Destination.Action.debugUserDefaultsContents,
			destination: { DebugUserDefaultsContents.View(store: $0) }
		)
	}

	#if DEBUG
	private func debugKeychainTest(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.debugKeychainTest,
			action: DebugSettingsCoordinator.Destination.Action.debugKeychainTest,
			destination: { DebugKeychainTest.View(store: $0) }
		)
	}
	#endif // DEBUG

	private func factorSources(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.debugManageFactorSources,
			action: DebugSettingsCoordinator.Destination.Action.debugManageFactorSources,
			destination: { DebugManageFactorSources.View(store: $0) }
		)
	}

	private func debugInspectProfile(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.debugInspectProfile,
			action: DebugSettingsCoordinator.Destination.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}

	private func securityStructureConfigs(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.securityStructureConfigs,
			action: DebugSettingsCoordinator.Destination.Action.securityStructureConfigs,
			destination: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
		)
	}
}

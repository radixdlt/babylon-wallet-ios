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
			.destinations(with: store)
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

private extension StoreOf<DebugSettingsCoordinator> {
	var destination: PresentationStoreOf<DebugSettingsCoordinator.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DebugSettingsCoordinator>) -> some View {
		let destinationStore = store.destination
		return factorSources(with: destinationStore)
			.debugUserDefaultsContents(with: destinationStore)
		#if DEBUG
			.debugKeychainTest(with: destinationStore)
			.debugKeychainContents(with: destinationStore)
		#endif
			.debugInspectProfile(with: destinationStore)
			.securityStructureConfigs(with: destinationStore)
	}

	private func debugUserDefaultsContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.debugUserDefaultsContents,
			action: DebugSettingsCoordinator.Destination_.Action.debugUserDefaultsContents,
			destination: { DebugUserDefaultsContents.View(store: $0) }
		)
	}

	#if DEBUG
	private func debugKeychainTest(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.debugKeychainTest,
			action: DebugSettingsCoordinator.Destination_.Action.debugKeychainTest,
			destination: { DebugKeychainTest.View(store: $0) }
		)
	}

	@MainActor
	func debugKeychainContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.debugKeychainContents,
			action: DebugSettingsCoordinator.Destination_.Action.debugKeychainContents,
			destination: { DebugKeychainContents.View(store: $0) }
		)
	}
	#endif // DEBUG

	private func factorSources(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.debugManageFactorSources,
			action: DebugSettingsCoordinator.Destination_.Action.debugManageFactorSources,
			destination: { DebugManageFactorSources.View(store: $0) }
		)
	}

	private func debugInspectProfile(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.debugInspectProfile,
			action: DebugSettingsCoordinator.Destination_.Action.debugInspectProfile,
			destination: { DebugInspectProfile.View(store: $0) }
		)
	}

	private func securityStructureConfigs(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination_>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination_.State.securityStructureConfigs,
			action: DebugSettingsCoordinator.Destination_.Action.securityStructureConfigs,
			destination: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
		)
	}
}

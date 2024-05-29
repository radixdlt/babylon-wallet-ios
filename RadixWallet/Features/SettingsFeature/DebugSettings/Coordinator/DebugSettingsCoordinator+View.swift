import ComposableArchitecture
import SwiftUI

// MARK: - DebugSettingsCoordinator.View
extension DebugSettingsCoordinator {
	public struct ViewState: Equatable {}

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
		ScrollView {
			VStack(spacing: .zero) {
				ForEachStatic(rows) { kind in
					SettingsRow(kind: kind, store: store)
				}
			}
		}
		.padding(.bottom, .large3)
		.radixToolbar(title: "Debug Settings")
		.destinations(with: store)
		.tint(.app.gray1)
		.foregroundColor(.app.gray1)
		.presentsLoadingViewOverlay()
	}

	@MainActor
	private var rows: [SettingsRow<DebugSettingsCoordinator>.Kind] {
		[
			// ONLY DEBUG EVER
			.model(
				title: "Factor sources",
				icon: .systemImage("person.badge.key"),
				action: .factorSourcesButtonTapped
			),
			// ONLY DEBUG EVER
			.model(
				title: "Inspect profile",
				icon: .systemImage("wallet.pass"),
				action: .debugInspectProfileButtonTapped
			),
			// ONLY DEBUG EVER
			.model(
				title: "UserDefaults content",
				icon: .systemImage("person.text.rectangle"),
				action: .debugUserDefaultsContentsButtonTapped
			),
			// ONLY DEBUG EVER
			.model(
				title: "Keychain Test",
				icon: .systemImage("key"),
				action: .debugTestKeychainButtonTapped
			),
			// ONLY DEBUG EVER
			.model(
				title: "Keychain Contents",
				icon: .systemImage("key"),
				action: .debugKeychainContentsButtonTapped
			),
			.model(
				title: "Dapp linking delay",
				icon: .systemImage("cloud"),
				action: .dappLinkingDelayTapped
			),
		]
	}
}

// MARK: - Extensions

private extension StoreOf<DebugSettingsCoordinator> {
	var destination: PresentationStoreOf<DebugSettingsCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<DebugSettingsCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
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
			.dappLinkingDelay(with: destinationStore)
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

	private func debugKeychainContents(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.debugKeychainContents,
			action: DebugSettingsCoordinator.Destination.Action.debugKeychainContents,
			destination: { DebugKeychainContents.View(store: $0) }
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

	private func dappLinkingDelay(
		with destinationStore: PresentationStoreOf<DebugSettingsCoordinator.Destination>
	) -> some View {
		navigationDestination(
			store: destinationStore,
			state: /DebugSettingsCoordinator.Destination.State.dappLinkingDelay,
			action: DebugSettingsCoordinator.Destination.Action.dappLinkingDelay,
			destination: { DappLinkingDelay.View(store: $0) }
		)
	}
}

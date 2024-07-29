import ComposableArchitecture
import SwiftUI

// MARK: - RestoreProfileFromBackupCoordinator.View
extension RestoreProfileFromBackupCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<RestoreProfileFromBackupCoordinator>

		public init(store: StoreOf<RestoreProfileFromBackupCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SelectBackup.View(store: store.selectBackup)
				.inNavigationStack
				.destinations(with: store)
		}
	}
}

private extension StoreOf<RestoreProfileFromBackupCoordinator> {
	var selectBackup: StoreOf<SelectBackup> {
		scope(state: \.selectBackup, action: \.child.selectBackup)
	}

	var destination: PresentationStoreOf<RestoreProfileFromBackupCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<RestoreProfileFromBackupCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<RestoreProfileFromBackupCoordinator>) -> some View {
		let destinationStore = store.destination
		return importMnemonics(with: destinationStore)
	}

	private func importMnemonics(with destinationStore: PresentationStoreOf<RestoreProfileFromBackupCoordinator.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.importMnemonicsFlow, action: \.importMnemonicsFlow)) {
			ImportMnemonicsFlowCoordinator.View(store: $0)
		}
	}
}

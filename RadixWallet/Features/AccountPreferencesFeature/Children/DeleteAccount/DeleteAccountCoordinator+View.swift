import ComposableArchitecture
import SwiftUI

// MARK: - DeleteAccountCoordinator.View
extension DeleteAccountCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DeleteAccountCoordinator>

		var body: some SwiftUI.View {
			DeleteAccountConfirmation.View(store: store.deleteConfirmation)
				.destinations(with: store)
		}
	}
}

extension StoreOf<DeleteAccountCoordinator> {
	var deleteConfirmation: StoreOf<DeleteAccountConfirmation> {
		scope(state: \.deleteConfirmation, action: \.child.deleteConfirmation)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<DeleteAccountCoordinator>) -> some View {
		let destinationStore = store.scope(state: \.$destination, action: \.destination)
		return chooseReceivingAccount(with: destinationStore, store: store)
			.accountDeleted(with: destinationStore, store: store)
	}

	private func chooseReceivingAccount(with destinationStore: PresentationStoreOf<DeleteAccountCoordinator.Destination>, store: StoreOf<DeleteAccountCoordinator>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.chooseReceivingAccount, action: \.chooseReceivingAccount)) {
			ChooseReceivingAccountOnDelete.View(store: $0)
		}
	}

	private func accountDeleted(with destinationStore: PresentationStoreOf<DeleteAccountCoordinator.Destination>, store: StoreOf<DeleteAccountCoordinator>) -> some View {
		navigationDestination(store: destinationStore.scope(state: \.accountDeleted, action: \.accountDeleted)) { _ in
			AccountDeletedView {
				store.send(.view(.goHomeButtonTapped))
			}
		}
	}
}

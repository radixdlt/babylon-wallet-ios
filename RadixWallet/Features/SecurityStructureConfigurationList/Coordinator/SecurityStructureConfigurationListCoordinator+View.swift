import ComposableArchitecture
import SwiftUI

// MARK: - SecurityStructureConfigurationListCoordinator.View
extension SecurityStructureConfigurationListCoordinator {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SecurityStructureConfigurationListCoordinator>

		public init(store: StoreOf<SecurityStructureConfigurationListCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SecurityStructureConfigurationList.View(
				store: store.scope(
					state: \.configList,
					action: { .child(.configList($0)) }
				)
			)
			.destinations(with: store)
		}
	}
}

private extension StoreOf<SecurityStructureConfigurationListCoordinator> {
	var destination: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination> {
		func scopeState(state: State) -> PresentationState<SecurityStructureConfigurationListCoordinator.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

private extension View {
	@MainActor
	func destinations(with store: StoreOf<SecurityStructureConfigurationListCoordinator>) -> some View {
		let destinationStore = store.destination
		return manageSecurityStructureCoordinator(with: destinationStore)
	}

	@MainActor
	private func manageSecurityStructureCoordinator(with destinationStore: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SecurityStructureConfigurationListCoordinator.Destination.State.manageSecurityStructureCoordinator,
			action: SecurityStructureConfigurationListCoordinator.Destination.Action.manageSecurityStructureCoordinator,
			content: { ManageSecurityStructureCoordinator.View(store: $0) }
		)
	}
}

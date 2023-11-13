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
	var destination: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination_> {
		func toState(_ parentState: State) -> PresentationState<SecurityStructureConfigurationListCoordinator.Destination_.State> {
			parentState.$destination
		}
		return scope(state: toState, action: Action.destination)
	}
}

private extension View {
	@MainActor
	func destinations(with store: StoreOf<SecurityStructureConfigurationListCoordinator>) -> some View {
		let destinationStore = store.destination
		return manageSecurityStructureCoordinator(with: destinationStore)
	}

	@MainActor
	private func manageSecurityStructureCoordinator(with destinationStore: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination_>) -> some View {
		sheet(
			store: destinationStore,
			state: /SecurityStructureConfigurationListCoordinator.Destination_.State.manageSecurityStructureCoordinator,
			action: SecurityStructureConfigurationListCoordinator.Destination_.Action.manageSecurityStructureCoordinator,
			content: { ManageSecurityStructureCoordinator.View(store: $0) }
		)
	}
}

// #if DEBUG
// import SwiftUI
import ComposableArchitecture //
//// MARK: - SecurityStructureConfigurationList_Preview
// struct SecurityStructureConfigurationList_Preview: PreviewProvider {
//	static var previews: some View {
//		SecurityStructureConfigurationListCoordinator.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SecurityStructureConfigurationListCoordinator.init
//			)
//		)
//	}
// }
//
// extension SecurityStructureConfigurationListCoordinator.State {
//	public static let previewValue = Self()
// }
// #endif

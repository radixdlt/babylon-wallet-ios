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
			.destination(store: store)
		}
	}
}

extension View {
	@MainActor
	fileprivate func destination(store: StoreOf<SecurityStructureConfigurationListCoordinator>) -> some View {
		manageSecurityStructureCoordinator(with: store.destination)
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

private extension StoreOf<SecurityStructureConfigurationListCoordinator> {
	var destination: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination> {
		scope(state: \.$destination) { .child(.destination($0)) }
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

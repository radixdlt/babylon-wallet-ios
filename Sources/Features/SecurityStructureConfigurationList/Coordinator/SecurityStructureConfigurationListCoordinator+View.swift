import CreateSecurityStructureFeature
import FeaturePrelude

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
		let destinationStore = store.scope(state: \.$destination, action: { .child(.destination($0)) })
		return createSecurityStructureCoordinator(with: destinationStore)
			.details(with: destinationStore)
	}

	@MainActor
	private func createSecurityStructureCoordinator(with destinationStore: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SecurityStructureConfigurationListCoordinator.Destination.State.createSecurityStructureConfig,
			action: SecurityStructureConfigurationListCoordinator.Destination.Action.createSecurityStructureConfig,
			content: { CreateSecurityStructureCoordinator.View(store: $0) }
		)
	}

	@MainActor
	private func details(with destinationStore: PresentationStoreOf<SecurityStructureConfigurationListCoordinator.Destination>) -> some View {
		sheet(
			store: destinationStore,
			state: /SecurityStructureConfigurationListCoordinator.Destination.State.securityStructureConfigDetails,
			action: SecurityStructureConfigurationListCoordinator.Destination.Action.securityStructureConfigDetails,
			content: { SecurityStructureConfigDetails.View(store: $0) }
		)
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SecurityStructureConfigurationList_Preview
// struct SecurityStructureConfigurationList_Preview: PreviewProvider {
//	static var previews: some View {
//		SecurityStructureConfigurationListCoordinator.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SecurityStructureConfigurationListCoordinator()
//			)
//		)
//	}
// }
//
// extension SecurityStructureConfigurationListCoordinator.State {
//	public static let previewValue = Self()
// }
// #endif

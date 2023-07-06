import FeaturePrelude
import SecurityStructureConfigurationListFeature
import TransactionReviewFeature

extension UpdateSecurityStateOfEntityCoordinator.State {
	var viewState: UpdateSecurityStateOfEntityCoordinator.ViewState {
		.init()
	}
}

extension UpdateSecurityStateOfEntityCoordinator {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<UpdateSecurityStateOfEntityCoordinator>

		public init(store: StoreOf<UpdateSecurityStateOfEntityCoordinator>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				path(for: store.scope(state: \.root, action: { .child(.root($0)) }))

					// This is required to disable the animation of internal components during transition
					.transaction { $0.animation = nil }
			} destination: {
				path(for: $0)
			}
		}

		func path(
			for store: StoreOf<UpdateSecurityStateOfEntityCoordinator.Path>
		) -> some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /UpdateSecurityStateOfEntityCoordinator.Path.State.selectSecurityStructureConfig,
					action: UpdateSecurityStateOfEntityCoordinator.Path.Action.selectSecurityStructureConfig,
					then: { SecurityStructureConfigurationListCoordinator.View(store: $0) }
				)
				CaseLet(
					state: /UpdateSecurityStateOfEntityCoordinator.Path.State.factorInstancesFromFactorSources,
					action: UpdateSecurityStateOfEntityCoordinator.Path.Action.factorInstancesFromFactorSources,
					then: { FactorInstancesFromFactorSourcesCoordinator.View(store: $0) }
				)
				CaseLet(
					state: /UpdateSecurityStateOfEntityCoordinator.Path.State.securifyEntity,
					action: UpdateSecurityStateOfEntityCoordinator.Path.Action.securifyEntity,
					then: { TransactionReview.View(store: $0) }
				)
			}
		}
	}
}

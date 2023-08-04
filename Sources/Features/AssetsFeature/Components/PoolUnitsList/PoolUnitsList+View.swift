import FeaturePrelude

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList>

		public init(store: StoreOf<PoolUnitsList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			IfLetStore(
				store.scope(
					state: \.lsuResource,
					action: (
						/PoolUnitsList.Action.child
							.. PoolUnitsList.ChildAction.lsuResource
					).embed
				),
				then: LSUResource.View.init
			)

			ForEachStore(
				store.scope(
					state: \.poolUnitTokens,
					action: (
						/PoolUnitsList.Action.child
							.. PoolUnitsList.ChildAction.poolUnitTokens
					).embed
				),
				content: PoolUnitToken.View.init
			)
		}
	}
}

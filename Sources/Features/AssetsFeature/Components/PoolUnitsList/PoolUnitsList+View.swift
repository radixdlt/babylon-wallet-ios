import FeaturePrelude

// MARK: - LSUResourceViewState
struct LSUResourceViewState: Equatable {
	let iconURL: URL
	let name: String
}

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList>

		public init(store: StoreOf<PoolUnitsList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ScrollView {
				IfLetStore(
					store.scope(
						state: \.lsuResource,
						action: (
							/PoolUnitsList.Action.child .. PoolUnitsList.ChildAction.lsuResource
						).embed
					),
					then: LSUResource.View.init
				)
			}
		}
	}
}

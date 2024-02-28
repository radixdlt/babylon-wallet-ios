import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnitsList.View
extension PoolUnitsList {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnitsList>

		public init(store: StoreOf<PoolUnitsList>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			ForEachStore(
				store.scope(
					state: \.poolUnits,
					action: (
						/PoolUnitsList.Action.child
							.. PoolUnitsList.ChildAction.poolUnit
					).embed
				),
				content: {
					PoolUnit.View(store: $0)
				}
			)
		}
	}
}

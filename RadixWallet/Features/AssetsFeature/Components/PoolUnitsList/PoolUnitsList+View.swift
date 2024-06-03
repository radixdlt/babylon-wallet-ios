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
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				ForEach(viewStore.poolUnits) { poolUnit in
					Section {
						ResourceBalanceButton(.poolUnit(poolUnit.viewState), appearance: .assetList, isSelected: poolUnit.isSelected) {
							viewStore.send(.poolUnitWasTapped(poolUnit.id))
						}
						.rowStyle()
					}
				}
			}
		}
	}
}

private extension PoolUnitsList.State.PoolUnitState {
	var viewState: ResourceBalance.ViewState.PoolUnit {
		.init(poolUnit: poolUnit, details: resourceDetails)
	}
}

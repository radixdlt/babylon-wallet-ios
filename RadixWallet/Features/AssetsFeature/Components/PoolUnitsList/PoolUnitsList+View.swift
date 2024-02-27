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
						ResourceBalanceButton(resource: .poolUnit(poolUnit.viewState), appearance: .assetList, isSelected: poolUnit.isSelected) {
							viewStore.send(.poolUnitWasTapped(poolUnit.id))
						}
						.rowStyle()
					}
				}
			}
			.destinations(with: store)
			.task { @MainActor in
				await store.send(.view(.task)).finish()
			}
		}
	}
}

private extension PoolUnitsList.State.PoolUnitState {
	var viewState: ResourceBalance.PoolUnit {
		.init(poolUnit: poolUnit, details: resourceDetails)
	}
}

private extension StoreOf<PoolUnitsList> {
	var destination: PresentationStoreOf<PoolUnitsList.Destination> {
		func scopeState(state: State) -> PresentationState<PoolUnitsList.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PoolUnitsList>) -> some View {
		let destinationStore = store.destination
		return sheet(store: destinationStore.scope(state: \.details, action: \.details)) {
			PoolUnitDetails.View(store: $0)
		}
	}
}

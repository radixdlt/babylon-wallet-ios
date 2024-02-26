import ComposableArchitecture
import SwiftUI

// MARK: - PoolUnit.View
// TODO: This should go away, by removing the TCA stack for Pool Unit, instead PoolUnitView should be used directly.
extension PoolUnit {
	public typealias ViewState = PoolUnitView.ViewState

	public struct View: SwiftUI.View {
		private let store: StoreOf<PoolUnit>
		@Environment(\.refresh) var refresh

		public init(store: StoreOf<PoolUnit>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: PoolUnit.Action.view) { viewStore in
				Section {
					PoolUnitView(viewState: viewStore.state, background: .app.white) {
						viewStore.send(.didTap)
					}
					.rowStyle()
				}
				.border(.black, width: 5)
			}
			.destinations(with: store)
		}
	}
}

extension View {
	/// The common style for rows displayed in AssetsView
	func rowStyle() -> some View {
		self
			.listRowInsets(.init())
			.listRowSeparator(.hidden)
	}
}

extension PoolUnit.State {
	var viewState: PoolUnit.ViewState {
		.init(
			poolName: poolUnit.resource.metadata.fungibleResourceName,
			amount: nil, // In this contextwe don't want to show any amount
			guaranteedAmount: nil,
			dAppName: resourceDetails.dAppName,
			poolIcon: poolUnit.resource.metadata.iconURL,
			resources: resourceDetails.map { .init(resources: $0) },
			isSelected: isSelected
		)
	}
}

private extension StoreOf<PoolUnit> {
	var destination: PresentationStoreOf<PoolUnit.Destination> {
		func scopeState(state: State) -> PresentationState<PoolUnit.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<PoolUnit>) -> some View {
		let destinationStore = store.destination
		return sheet(
			store: destinationStore,
			state: /PoolUnit.Destination.State.details,
			action: PoolUnit.Destination.Action.details,
			content: { PoolUnitDetails.View(store: $0) }
		)
	}
}

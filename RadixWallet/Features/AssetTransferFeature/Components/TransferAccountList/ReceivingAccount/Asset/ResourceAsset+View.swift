import ComposableArchitecture
import SwiftUI

extension ResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ResourceAsset>
		@FocusState
		private var focused: Bool

		public init(store: StoreOf<ResourceAsset>) {
			self.store = store
		}
	}
}

extension ResourceAsset.View {
	public var body: some View {
		VStack(spacing: .small3) {
			HStack {
				SwitchStore(store.scope(state: \.kind, action: \.child)) { state in
					switch state {
					case .fungibleAsset:
						CaseLet(
							/ResourceAsset.State.Kind.fungibleAsset,
							action: ResourceAsset.ChildAction.fungibleAsset,
							then: { FungibleResourceAsset.View(store: $0) }
						)

					case .nonFungibleAsset:
						CaseLet(
							/ResourceAsset.State.Kind.nonFungibleAsset,
							action: ResourceAsset.ChildAction.nonFungibleAsset,
							then: { NonFungibleResourceAsset.View(store: $0) }
						)
					}
				}
				.background(.app.white)
				.focused($focused)
				.roundedCorners(strokeColor: focused ? .app.gray1 : .app.white)
				.tokenRowShadow()

				Spacer()

				Button {
					store.send(.view(.removeTapped))
				} label: {
					Image(asset: AssetResource.close)
						.frame(.smallest)
				}
				.foregroundColor(.app.gray2)
			}

			WithViewStore(store, observe: \.additionalSignatureRequired) { viewStore in
				if viewStore.state {
					WarningErrorView(text: "Additional signature required to deposit", type: .warning)
				}
			}
		}
		.destinations(with: store)
	}
}

private extension StoreOf<ResourceAsset> {
	var destination: PresentationStoreOf<ResourceAsset.Destination> {
		func scopeState(state: State) -> PresentationState<ResourceAsset.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<ResourceAsset>) -> some View {
		let destinationStore = store.destination
		return fungibleTokenDetails(with: destinationStore)
			.nonFungibleTokenDetails(with: destinationStore)
			.lsuDetails(with: destinationStore)
			.poolUnitDetails(with: destinationStore)
	}

	private func fungibleTokenDetails(with destinationStore: PresentationStoreOf<ResourceAsset.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.fungibleTokenDetails, action: \.fungibleTokenDetails)) {
			FungibleTokenDetails.View(store: $0)
		}
	}

	private func nonFungibleTokenDetails(with destinationStore: PresentationStoreOf<ResourceAsset.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.nonFungibleTokenDetails, action: \.nonFungibleTokenDetails)) {
			NonFungibleTokenDetails.View(store: $0)
		}
	}

	private func lsuDetails(with destinationStore: PresentationStoreOf<ResourceAsset.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.lsuDetails, action: \.lsuDetails)) {
			LSUDetails.View(store: $0)
		}
	}

	private func poolUnitDetails(with destinationStore: PresentationStoreOf<ResourceAsset.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.poolUnitDetails, action: \.poolUnitDetails)) {
			PoolUnitDetails.View(store: $0)
		}
	}
}

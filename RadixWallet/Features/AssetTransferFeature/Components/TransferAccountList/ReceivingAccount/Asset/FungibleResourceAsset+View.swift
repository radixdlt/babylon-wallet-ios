import ComposableArchitecture
import SwiftUI

extension FungibleResourceAsset {
	typealias ViewState = State

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<FungibleResourceAsset>

		@FocusState
		private var focused: Bool

		init(store: StoreOf<FungibleResourceAsset>) {
			self.store = store
		}
	}
}

extension FungibleResourceAsset.ViewState {
	var resourceBalance: ResourceBalance.ViewState {
		.fungible(.init(resource: resource, isXRD: isXRD).withoutAmount)
	}

	var thumbnail: Thumbnail.TokenContent {
		isXRD ? .xrd : .other(resource.metadata.iconURL)
	}
}

extension ViewStore<FungibleResourceAsset.State, FungibleResourceAsset.ViewAction> {
	var focusedBinding: Binding<Bool> {
		binding(get: \.focused, send: ViewAction.focusChanged)
	}
}

extension FungibleResourceAsset.View {
	var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .trailing) {
				ResourceBalanceView(viewStore.resourceBalance, appearance: .compact) {
					viewStore.send(.resourceTapped)
				}
				.withAuxiliary(spacing: .small2) {
					TextField(
						Decimal192.zero.formatted(),
						text: viewStore.binding(
							get: \.transferAmountStr,
							send: { .amountChanged($0) }
						)
					)
					.keyboardType(.decimalPad)
					.multilineTextAlignment(.trailing)
					.lineLimit(1)
					.minimumScaleFactor(0.7)
					.foregroundColor(.primaryText)
					.textStyle(.sectionHeader)
					.focused($focused)
					.bind(viewStore.focusedBinding, to: $focused)
				}

				if viewStore.totalExceedsBalance {
					// TODO: Add better style
					Text(L10n.AssetTransfer.FungibleResource.totalExceedsBalance)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.red1)
				}

				if focused {
					HStack {
						Button {
							viewStore.send(.maxAmountTapped)
						} label: {
							Text(L10n.Common.max)
								.underline()
								.textStyle(.body3HighImportance)
								.foregroundColor(.app.blue2)
						}

						Group {
							Text("-")
							Text(L10n.AssetTransfer.FungibleResource.balance(viewStore.balance.formatted()))
						}
						.textStyle(.body3HighImportance)
						.foregroundColor(.secondaryText)
					}
				}
			}
			.padding(.medium3)
			.destinations(with: store)
		}
	}
}

private extension StoreOf<FungibleResourceAsset> {
	var destination: PresentationStoreOf<FungibleResourceAsset.Destination> {
		func scopeState(state: State) -> PresentationState<FungibleResourceAsset.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<FungibleResourceAsset>) -> some View {
		let destinationStore = store.destination
		return chooseXRDAmount(with: destinationStore)
			.needsToPayFeeFromOtherAccount(with: destinationStore)
	}

	private func chooseXRDAmount(with destinationStore: PresentationStoreOf<FungibleResourceAsset.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /FungibleResourceAsset.Destination.State.chooseXRDAmount,
			action: FungibleResourceAsset.Destination.Action.chooseXRDAmount
		)
	}

	private func needsToPayFeeFromOtherAccount(with destinationStore: PresentationStoreOf<FungibleResourceAsset.Destination>) -> some View {
		alert(
			store: destinationStore,
			state: /FungibleResourceAsset.Destination.State.needsToPayFeeFromOtherAccount,
			action: FungibleResourceAsset.Destination.Action.needsToPayFeeFromOtherAccount
		)
	}
}

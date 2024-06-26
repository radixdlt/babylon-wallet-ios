import ComposableArchitecture
import SwiftUI

extension FungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<FungibleResourceAsset>

		@FocusState
		private var focused: Bool

		public init(store: StoreOf<FungibleResourceAsset>) {
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
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack(alignment: .trailing) {
				ResourceBalanceView(viewStore.resourceBalance, appearance: .compact)
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
						.foregroundColor(.app.gray1)
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
						.foregroundColor(.app.gray2)
					}
				}
			}
			.padding(.medium3)
			.alert(store: store.alert)
		}
	}
}

private extension StoreOf<FungibleResourceAsset> {
	var alert: AlertPresentationStore<FungibleResourceAsset.ViewAction.Alert> {
		scope(state: \.$alert, action: { .view(.alert($0)) })
	}
}

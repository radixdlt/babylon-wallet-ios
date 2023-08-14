import FeaturePrelude
import TransactionClient

extension NormalCustomizationFees.State {
	var viewState: NormalCustomizationFees.ViewState {
		.init(
			feesViewState: .init(feeViewStates: fees.viewStates, totalFee: fees.total)
		)
	}
}

extension NormalCustomizationFees {
	public struct ViewState: Equatable, Sendable {
		let feesViewState: FeesView.ViewState
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<NormalCustomizationFees>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState) { viewStore in
				FeesView(viewState: viewStore.feesViewState)
			}
		}
	}
}

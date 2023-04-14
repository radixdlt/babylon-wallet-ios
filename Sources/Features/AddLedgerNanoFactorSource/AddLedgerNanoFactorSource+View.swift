import FeaturePrelude

extension AddLedgerNanoFactorSource.State {
	var viewState: AddLedgerNanoFactorSource.ViewState {
		.init()
	}
}

// MARK: - AddLedgerNanoFactorSource.View
extension AddLedgerNanoFactorSource {
	public struct ViewState: Equatable {}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AddLedgerNanoFactorSource>

		public init(store: StoreOf<AddLedgerNanoFactorSource>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					Button("MOCK LEDGER ADDED") {
						viewStore.send(.mockLedgerNanoAdded)
					}
					.buttonStyle(.primaryRectangular)
				}
				.padding(.horizontal, .medium3)
				.task {
					await ViewStore(store.stateless).send(.view(.task)).finish()
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - AddLedgerNanoFactorSource_Preview
struct AddLedgerNanoFactorSource_Preview: PreviewProvider {
	static var previews: some View {
		AddLedgerNanoFactorSource.View(
			store: .init(
				initialState: .previewValue,
				reducer: AddLedgerNanoFactorSource()
			)
		)
	}
}

extension AddLedgerNanoFactorSource.State {
	public static let previewValue = Self()
}
#endif

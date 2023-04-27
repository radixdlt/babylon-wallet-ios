import FeaturePrelude

extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init(txID: notarizedTX.txID, status: status)
	}
}

extension SubmitTransaction.State.TXStatus {
	var display: String {
		switch self {
		case .notYetSubmitted, .submitting: return "Submitting"
		case .submittedUnknown, .submittedPending: return "Submitted but not confirmed"
		case .rejected: return "Rejected"
		case .committedFailure: return "Failed"
		case .committedSuccessfully: return "Successfully commited"
		}
	}
}

// MARK: - SubmitTransaction.View
extension SubmitTransaction {
	public struct ViewState: Equatable {
		// TODO: declare some properties
		let txID: TXID
		let status: SubmitTransaction.State.TXStatus
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SubmitTransaction>

		public init(store: StoreOf<SubmitTransaction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					VPair(heading: "TXID", item: viewStore.txID)
					VPair(heading: "Status", item: viewStore.status.display)
				}
				.padding(.medium1)
				.onAppear { viewStore.send(.appeared) }
				.navigationTitle("Submitting Transaction")
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - SubmitTransaction_Preview
// struct SubmitTransaction_Preview: PreviewProvider {
//	static var previews: some View {
//		SubmitTransaction.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: SubmitTransaction()
//			)
//		)
//	}
// }
//
// extension SubmitTransaction.State {
//	public static let previewValue = Self()
// }
// #endif

import FeaturePrelude

extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init(txID: notarizedTX.txID, status: status)
	}
}

extension SubmitTransaction.State.TXStatus {
	var display: String {
		switch self {
		case .notYetSubmitted, .submitting: return L10n.TransactionReview.SubmitTransaction.displaySubmitting
		case .submittedUnknown, .submittedPending: return L10n.TransactionReview.SubmitTransaction.displaySubmittedUnknown
		case .rejected: return L10n.TransactionReview.SubmitTransaction.displayRejected
		case .committedFailure: return L10n.TransactionReview.SubmitTransaction.displayFailed
		case .committedSuccessfully: return L10n.TransactionReview.SubmitTransaction.displayCommitted
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
                                        switch viewStore.status {
                                        case .submitting, .submittedPending, .submittedUnknown, .notYetSubmitted:
                                                Image(asset: AssetResource.transactionInProgress)
                                                Text("Completing Transaction...").textStyle(.body1Regular)
                                        default:
                                                EmptyView()
                                        }
				}
				.padding(.medium1)
				.onFirstTask { @MainActor in
					await viewStore.send(.appeared).finish()
				}
				.presentationDragIndicator(.visible)
				.presentationDetents([.fraction(0.5)])
				#if os(iOS)
					.presentationBackground(.blur)
				#endif
			}
		}
	}
}

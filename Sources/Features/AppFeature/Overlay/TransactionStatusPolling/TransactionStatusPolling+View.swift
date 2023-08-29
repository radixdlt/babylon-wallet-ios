import EngineKit
import FeaturePrelude

extension TransactionStatusPolling.State {
	var viewState: TransactionStatusPolling.ViewState {
		.init(
			txID: txID,
			status: status,
			disableDismiss: disableInProgressDismissal && status.inProgress
		)
	}
}

extension TransactionStatusPolling.State.TXStatus {
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
extension TransactionStatusPolling {
	public struct ViewState: Equatable {
		let txID: TXID
		let status: TransactionStatusPolling.State.TXStatus
		let disableDismiss: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		@SwiftUI.State private var opacity: Double = 1.0

		private let store: StoreOf<TransactionStatusPolling>

		public init(store: StoreOf<TransactionStatusPolling>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				WithNavigationBar {
					if !viewStore.disableDismiss {
						viewStore.send(.closeButtonTapped)
					}
				} content: {
					VStack(spacing: .small1) {
						if viewStore.status.inProgress {
							Image(asset: AssetResource.transactionInProgress)
								.opacity(opacity)
								.animation(
									.easeInOut(duration: 0.3)
										.delay(0.2)
										.repeatForever(autoreverses: true),
									value: opacity
								)
								.onAppear {
									opacity = 0.5
								}

							Text("Completing Transaction...") // FIXME: strings
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)

						} else if viewStore.status.isCompletedSuccessfully {
							Image(asset: AssetResource.successCheckmark)

							Text("Success") // FIXME: strings
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)

							Text("Your transaction was successful") // FIXME: strings
								.textStyle(.body1Regular)
						} else if viewStore.status.isCompletedWithFailure {
							Image(asset: AssetResource.warningError)
						}

						HStack {
							Text("Transaction ID: ") // FIXME: strings
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)
							AddressView(.identifier(.transaction(viewStore.txID)))
						}
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .medium3)
				}
//				.frame(maxWidth: .infinity)
				.onFirstTask { @MainActor in
					viewStore.send(.appeared)
				}
				.presentationDragIndicator(.visible)
				.presentationDetents([.fraction(0.5)])
				.interactiveDismissDisabled(viewStore.disableDismiss)
			}
		}
	}
}

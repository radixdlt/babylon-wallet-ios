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
		@SwiftUI.State var animationAmount: Double = 1.0

		public init(store: StoreOf<SubmitTransaction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium1) {
					Image(asset: AssetResource.transactionInProgress)
						.opacity(animationAmount)
						.animation(
							.linear(duration: 0.3)
								.delay(0.2)
								.repeatForever(autoreverses: true),
							value: animationAmount
						)
						.onAppear {
							animationAmount = 0.5
						}
					Text("Completing Transaction...").textStyle(.body1Regular)
				}
				.onWillDisappear {
					viewStore.send(.willDisappear)
				}
				.padding(.horizontal, .small2)
				.padding(.bottom, .medium3)
				.frame(maxWidth: .infinity)
				.safeAreaInset(edge: .top, alignment: .leading, spacing: 0) {
					CloseButton { viewStore.send(.closeButtonTapped) }
						.padding([.top, .leading], .small2)
				}
				.onFirstTask { @MainActor in
					viewStore.send(.appeared)
				}
				.presentationDragIndicator(.visible)
				.presentationDetentIntrinsicHeight()
				#if os(iOS)
					.presentationBackground(.blur)
				#endif
			}
		}
	}
}

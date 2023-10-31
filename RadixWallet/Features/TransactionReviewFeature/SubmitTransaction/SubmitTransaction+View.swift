import ComposableArchitecture
import SwiftUI
extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init(
			txID: notarizedTX.txID,
			status: status,
			dismissalDisabled: inProgressDismissalDisabled && status.isLoading
		)
	}
}

extension TXFailureStatus {
	var display: String {
		switch self {
		case .failed:
			"Your transaction was processed, but had a problem that caused it to fail permanently"
		case .permanentlyRejected:
			"Your transaction was improperly constructed and cannot be processed"
		case .temporarilyRejected:
			"Your transaction could not be processed, but could potentially still be processed within the next 50 minutes"
		}
	}
}

extension Error {
	fileprivate var display: String {
		if case let failure as TXFailureStatus = self {
			failure.display
		} else {
			"Transaction was rejected as invalid by the Radix Network"
		}
	}
}

// MARK: - SubmitTransaction.View
extension SubmitTransaction {
	public struct ViewState: Equatable {
		let txID: TXID
		let status: Loadable<EqVoid>
		let dismissalDisabled: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		@SwiftUI.State private var opacity: Double = 1.0

		private let store: StoreOf<SubmitTransaction>

		public init(store: StoreOf<SubmitTransaction>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				WithNavigationBar {
					viewStore.send(.closeButtonTapped)
				} content: {
					VStack(spacing: .medium2) {
						switch viewStore.status {
						case let .failure(error):
							Image(asset: AssetResource.warningError)
							Text(L10n.Transaction.Status.Failure.title)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)
								.multilineTextAlignment(.center)

							Text(error.display) // FIXME: Strings
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
						default:
							Image(asset: AssetResource.transactionInProgress)
								.opacity(opacity)
								.animation(
									.easeInOut(duration: 0.3)
										.delay(0.2)
										.repeatForever(autoreverses: true),
									value: opacity
								)
								.onAppear {
									withAnimation {
										opacity = 0.5
									}
								}

							Text(L10n.Transaction.Status.Completing.text)
								.textStyle(.body1Regular)
						}

						HStack {
							Text(L10n.TransactionReview.SubmitTransaction.txID)
							AddressView(.identifier(.transaction(viewStore.txID)))
						}
					}
					.padding(.horizontal, .medium2)
					.padding(.bottom, .medium3)
				}
				.onFirstTask { @MainActor in
					viewStore.send(.appeared)
				}
				.alert(store: store.scope(state: \.$dismissTransactionAlert, action: { .view(.dismissTransactionAlert($0)) }))
				.interactiveDismissDisabled(true)
				.presentationDragIndicator(.visible)
				.presentationDetents([.fraction(0.66)])
				.presentationBackground(.blur)
			}
		}
	}
}

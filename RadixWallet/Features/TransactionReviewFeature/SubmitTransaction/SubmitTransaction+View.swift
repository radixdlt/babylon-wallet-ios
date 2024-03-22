import ComposableArchitecture
import SwiftUI

extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init(
			txID: notarizedTX.txID,
			status: status,
			dismissalDisabled: inProgressDismissalDisabled && status.isInProgress
		)
	}
}

extension SubmitTransaction.State.TXStatus {
	var display: String {
		switch self {
		case .failed(.applicationError(.worktopError(.assertionFailed))),
		     .permanentlyRejected(.applicationError(.worktopError(.assertionFailed))):
			L10n.TransactionStatus.AssertionFailure.text
		case .failed:
			L10n.TransactionStatus.Failed.text
		case .permanentlyRejected:
			L10n.TransactionStatus.Rejected.text
		case let .temporarilyRejected(processingTime):
			L10n.TransactionStatus.Error.text(processingTime)
		case .notYetSubmitted, .submitting, .submitted:
			L10n.TransactionStatus.Completing.text
		case .committedSuccessfully:
			""
		}
	}

	var errorTitle: String {
		switch self {
		case .notYetSubmitted, .submitting, .submitted, .committedSuccessfully:
			"" // Not applicable
		case .temporarilyRejected:
			L10n.TransactionStatus.Error.title
		case .permanentlyRejected:
			L10n.TransactionStatus.Rejected.title
		case .failed:
			L10n.TransactionStatus.Failed.title
		}
	}
}

// MARK: - SubmitTransaction.View
extension SubmitTransaction {
	public struct ViewState: Equatable {
		let txID: TXID
		let status: State.TXStatus
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
						if viewStore.status.failed {
							Image(asset: AssetResource.warningError)
							Text(viewStore.status.errorTitle)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)
								.multilineTextAlignment(.center)
						} else {
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
						}

						Text(viewStore.status.display)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						HStack {
							Text(L10n.TransactionReview.SubmitTransaction.txID)
							AddressView(.identifier(.transaction(viewStore.txID)))
						}
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)
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

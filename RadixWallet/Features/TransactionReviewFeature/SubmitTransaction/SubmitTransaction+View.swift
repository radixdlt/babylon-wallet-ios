import ComposableArchitecture
import SwiftUI

extension SubmitTransaction.State {
	var viewState: SubmitTransaction.ViewState {
		.init(
			txID: notarizedTX.txID,
			status: status,
			dismissalDisabled: inProgressDismissalDisabled && status.isInProgress,
			showSwitchBackToBrowserMessage: route.isDeepLink
		)
	}
}

extension SubmitTransaction.State.TXStatus {
	var display: String {
		switch self {
		case .failed(.worktopError), .permanentlyRejected(.worktopError):
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
	struct ViewState: Equatable {
		let txID: TransactionIntentHash
		let status: State.TXStatus
		let dismissalDisabled: Bool
		let showSwitchBackToBrowserMessage: Bool
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SubmitTransaction>

		@ScaledMetric private var height: CGFloat = 360

		init(store: StoreOf<SubmitTransaction>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				WithNavigationBar {
					viewStore.send(.closeButtonTapped)
				} content: {
					VStack(spacing: .zero) {
						Spacer()
						if viewStore.status.failed {
							Image(.errorLarge)
							Text(viewStore.status.errorTitle)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .medium2)
								.padding(.top, .medium3)
						} else {
							InteractionReview.InteractionInProgressView()
						}

						Text(viewStore.status.display)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .medium2)
							.padding(.top, .medium3)

						AddressView(.transaction(viewStore.txID), imageColor: .app.gray2)
							.foregroundColor(.app.blue1)
							.textStyle(.body1Header)
							.padding(.horizontal, .medium2)
							.padding(.top, .small2)

						Spacer()
						if viewStore.status.failed, viewStore.showSwitchBackToBrowserMessage {
							Text(L10n.MobileConnect.interactionSuccess)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.vertical, .medium1)
								.frame(maxWidth: .infinity)
								.background(.app.gray5)
						}
					}
					.frame(maxWidth: .infinity)
				}
				.onFirstTask { @MainActor in
					viewStore.send(.appeared)
				}
				.alert(store: store.scope(state: \.$dismissTransactionAlert, action: { .view(.dismissTransactionAlert($0)) }))
				.interactiveDismissDisabled(viewStore.dismissalDisabled)
				.presentationDragIndicator(.visible)
				.presentationDetents(presentationDetents(status: viewStore.status))
				.presentationBackground(.blur)
			}
		}

		private func presentationDetents(status: State.TXStatus) -> Set<PresentationDetent> {
			if status.failed {
				[.height(height), .large]
			} else {
				[.height(height)]
			}
		}
	}
}

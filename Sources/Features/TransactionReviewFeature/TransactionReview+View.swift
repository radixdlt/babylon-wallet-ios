import ComposableArchitecture
import FeaturePrelude
import Profile

extension View {
	var sectionHeading: some View {
		textStyle(.body1Header)
			.foregroundColor(.app.gray2)
	}

	var message: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
	}
}

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init(
			message: message,
			networkFee: networkFee,
			showCustomizeguaranteesButton: true
		)
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	struct ViewState: Equatable {
		let message: String?
		let networkFee: BigDecimal
		let showCustomizeguaranteesButton: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReview>

		public init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium1) {
					if let message = viewStore.message {
						TransactionMessageView(message: message)
					}

					let withdrawingStore = store.scope(state: \.withdrawing) { .child(.account(id: $0, action: $1)) }
					IfLetStore(withdrawingStore) { accountsStore in
						Text("WITHDRAWING")
							.sectionHeading
							.flushedLeft
						Card(insetContents: true) {
							ForEachStore(accountsStore) { accountStore in
								TransactionReviewAccount.View(store: accountStore)
							}
						}
					}

					let depositingStore = store.scope(state: \.depositing) { .child(.account(id: $0, action: $1)) }
					IfLetStore(depositingStore) { accountsStore in
						Text("DEPOSITING")
							.sectionHeading
							.flushedLeft
						Card(insetContents: true) {
							ForEachStore(accountsStore) { accountStore in
								TransactionReviewAccount.View(store: accountStore)
							}
						}
					}

					if viewStore.showCustomizeguaranteesButton {
						Button("Customize guarantees") { // TODO: 
							viewStore.send(.customizeGuaranteesTapped)
						}
						.textStyle(.body1Header)
						.foregroundColor(.app.blue2)
						.padding(.vertical, .small3)
					}
				}
				.padding(30)
				.background(.app.gray5)
			}
		}
	}
}

// MARK: - TransactionMessageView
struct TransactionMessageView: View {
	let message: String

	var body: some View {
		VStack(spacing: .medium3) {
			Text("MESSAGE")
				.sectionHeading
				.flushedLeft

			Speechbubble {
				Text(message)
					.message
					.flushedLeft
					.padding(.horizontal, .medium3)
					.padding(.vertical, .small3)
			}
		}
	}
}

// MARK: - TransactionPresentingView
struct TransactionPresentingView: View {
	let presenters: IdentifiedArrayOf<TransactionReview.State.Dapp>
	let tapPresenterAction: (TransactionReview.State.Dapp.ID) -> Void

	var body: some View {
		Card {
			List(presenters) { presenter in
				Button {
					tapPresenterAction(presenter.id)
				} label: {
					HStack(spacing: .small1) {
						DappPlaceholder(size: .smallest)
						Text(presenter.name)
						Spacer(minLength: 0)
					}
				}
				.padding(.horizontal, .large2)
			}
		}
	}
}

// struct TransactionAccountsView: View {
//	let viewState: IdentifiedArrayOf<TransactionAccountView.ViewState>
//
//	let copyAction: (TransactionReview.State.Account.ID) -> Void
//	let customizeGuaranteesAction: () -> Void
//
//	var body: some View {
//	}
// }

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - TransactionReview_Preview
// struct TransactionReview_Preview: PreviewProvider {
//	static var previews: some View {
//		TransactionReview.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: TransactionReview()
//			)
//		)
//	}
// }
//
// extension TransactionReview.State {
//	public static let previewValue = Self()
// }
// #endif

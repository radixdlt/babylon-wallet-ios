import FeaturePrelude
import Profile

extension TransactionReview.State {
	var viewState: TransactionReview.ViewState {
		.init()
	}
}

private let accountString = "account_tdx_b_1pzq8y440g6nc4vuz0ghu84e84ak088fah9u6ad6j9dlqnuzk59"

private let testAccount0 = OnNetwork.AccountForDisplay(address: try! .init(address: accountString),
                                                       label: "My account",
                                                       appearanceID: ._4)

private let testAccount1 = OnNetwork.AccountForDisplay(address: try! .init(address: accountString),
                                                       label: "Other account",
                                                       appearanceID: ._3)

private let viewState0 = TransactionAccountView.ViewState(account: testAccount0,
                                                          currency: "XRD",
                                                          thumbnail: .userDirectory,
                                                          amount: .estimated(1.02044, dollars: 345.5422, guaranteed: 1.0134))

private let viewState1 = TransactionAccountView.ViewState(account: testAccount1,
                                                          currency: "XRD",
                                                          thumbnail: .userDirectory,
                                                          amount: .exact(134.2044, dollars: 35.5422))

extension View {
	var sectionHeading: some View {
		textCase(.uppercase)
			.textStyle(.body1Header)
			.foregroundColor(.app.gray2)
	}

	var message: some View {
		textStyle(.body1Regular)
			.foregroundColor(.app.gray1)
	}
}

// MARK: - TransactionReview.View
extension TransactionReview {
	struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReview>

		public init(store: StoreOf<TransactionReview>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { _ in
				VStack {
					Rectangle()
						.fill(.gray)
						.frame(width: 200, height: 60)
						.inSpeechbubble
						.border(.yellow)

					SpeechbubbleShape(cornerRadius: .medium3)
						.stroke(.orange)
						.frame(width: 200, height: 60)
						.border(.yellow)

					Text("Withdrawing")
						.sectionHeading
						.flushedLeft
					TransactionAccountView(viewState: viewState1) {} customizeGuaranteesAction: {}
						.padding(.bottom, 30)

					Text("Depositing")
						.sectionHeading
						.flushedLeft
					TransactionAccountView(viewState: viewState0) {} customizeGuaranteesAction: {}
				}
				.background(.app.gray5)
				.padding(30)
			}
		}
	}
}

// MARK: - TransactionMessageView
struct TransactionMessageView: View {
	let message: String

	var body: some View {
		Card {
			Text("Royalties claim")
				.message
		}
	}
}

// MARK: - TransactionAccountView
struct TransactionAccountView: View {
	struct ViewState: Equatable {
		let account: OnNetwork.AccountForDisplay
		let currency: String
		let thumbnail: URL
		let amount: TransactionAmountView.Amount

		var label: String { account.label.rawValue }
		var address: String { account.address.address }
		var gradient: Gradient { .init(account.appearanceID) }
	}

	let viewState: ViewState
	let copyAction: () -> Void
	let customizeGuaranteesAction: () -> Void

	var body: some View {
		Card(insetContents: true, verticalSpacing: .small1) {
			FlatCard {
				AccountLabel(viewState.label,
				             address: viewState.address,
				             gradient: viewState.gradient,
				             copyAction: copyAction)

				TransactionAmountView(currency: viewState.currency,
				                      thumbnail: viewState.thumbnail,
				                      amount: viewState.amount)
			}
			if case .estimated = viewState.amount {
				Button("Customize guarantees") { // TODO: 
					customizeGuaranteesAction()
				}
				.textStyle(.body1Header)
				.foregroundColor(.app.blue2)
				.padding(.vertical, .small3)
			}
		}
	}
}

// MARK: - TransactionAmountView
struct TransactionAmountView: View {
	enum Amount: Equatable {
		case exact(Double, dollars: Double)
		case estimated(Double, dollars: Double, guaranteed: Double)
	}

	let currency: String
	let thumbnail: URL
	let amount: Amount

	var body: some View {
		HStack(spacing: 0) {
			TokenView(name: currency, thumbnail: thumbnail)
				.padding(.vertical, .small1)
			Spacer(minLength: 0)
			AmountView(amount: amount)
				.padding(.vertical, .medium3)
		}
		.padding(.horizontal, .medium3)
		.background(.app.gray5)
	}

	struct TokenView: View {
		let name: String
		let thumbnail: URL

		var body: some View {
			TokenPlaceholder()
				.padding(.trailing, .small1)
			Text(name)
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray1)
		}
	}

	struct AmountView: View {
		let amount: Amount

		var body: some View {
			switch amount {
			case let .exact(amount, dollarAmount):
				coreView(amount: amount, dollarAmount: dollarAmount, isEstimated: false)

			case let .estimated(amount, dollarAmount, guaranteedAmount):
				VStack(alignment: .trailing, spacing: .small1) {
					coreView(amount: amount, dollarAmount: dollarAmount, isEstimated: true)

					Text("Guaranteed **\(guaranteedAmount.formatted(.number))**")
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray2)
				}
			}
		}

		@ViewBuilder
		private func coreView(amount: Double, dollarAmount: Double, isEstimated: Bool) -> some View {
			VStack(alignment: .trailing, spacing: .small1) {
				HStack(spacing: .small2) {
					if isEstimated {
						Text("Estimated") // TODO: 
							.textStyle(.body2Regular) // TODO:  unknown textStyle
					}
					Text(amount.formatted(.number))
						.textStyle(.secondaryHeader)
				}
				.foregroundColor(.app.gray1)

				Text(dollarAmount.formatted(.currency(code: "USD")))
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray1)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - TransactionReview_Preview
struct TransactionReview_Preview: PreviewProvider {
	static var previews: some View {
		TransactionReview.View(
			store: .init(
				initialState: .previewValue,
				reducer: TransactionReview()
			)
		)
	}
}

extension TransactionReview.State {
	public static let previewValue = Self()
}
#endif

import FeaturePrelude

extension TransactionReviewAccount.State {
	var viewState: TransactionReviewAccount.ViewState {
		switch account {
		case let .user(account):
			return .init(label: account.label.rawValue,
			             address: account.address.address,
			             gradient: .init(account.appearanceID),
			             details: details,
			             showApprovedMark: false)
		case let .external(accountAddress, approved):
			return .init(label: "Account", // TODO:  Localise
			             address: accountAddress.address,
			             gradient: .init(colors: [.app.gray2]),
			             details: details,
			             showApprovedMark: approved)
		}
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	struct ViewState: Equatable {
		let label: String
		let address: String
		let gradient: Gradient
		let details: [TransactionDetailsView.ViewState]
		let showApprovedMark: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccount>

		public init(store: StoreOf<TransactionReviewAccount>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				InnerCard {
					AccountLabel(viewStore.label,
					             address: viewStore.address,
					             gradient: viewStore.gradient) {
						viewStore.send(.copyAddress)
					}

					ForEach(viewStore.details, id: \.self) { details in
						TransactionDetailsView(viewState: details)
					}
				}
			}
		}
	}
}

// MARK: - TransactionDetailsView
public struct TransactionDetailsView: View {
	public typealias ViewState = TransactionReviewAccount.State.Details

	public let viewState: ViewState

	public var body: some View {
		switch viewState.transferred {
		case .nft:
			NFTView(name: viewState.metadata?.name,
			        thumbnail: viewState.metadata?.thumbnail)
		case let .token(amount, guaranteedAmount, dollarAmount):
			TokenView(name: viewState.metadata?.name,
			          thumbnail: viewState.metadata?.thumbnail,
			          amount: amount,
			          guaranteedAmount: guaranteedAmount,
			          dollarAmount: dollarAmount)
		}
	}

	struct NFTView: View {
		let name: String?
		let thumbnail: URL?

		var body: some View {
			HStack(spacing: .small1) {
				if let thumbnail {
					NFTPlaceholder(size: .small) // TODO:  Actually use URL
						.padding(.vertical, .small1)
				} else {
					NFTPlaceholder(size: .small)
						.padding(.vertical, .small1)
				}

				if let name {
					Text(name)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
				}

				Spacer(minLength: 0)
			}
			.padding(.horizontal, .medium3)
		}
	}

	struct TokenView: View {
		let name: String?
		let thumbnail: URL?

		let amount: BigDecimal
		let guaranteedAmount: BigDecimal?
		let dollarAmount: BigDecimal?

		var body: some View {
			HStack(spacing: .small1) {
				if let thumbnail {
					TokenPlaceholder(size: .small) // TODO:  Actually use URL
						.padding(.vertical, .small1)
				} else {
					TokenPlaceholder(size: .small)
						.padding(.vertical, .small1)
				}

				if let name {
					Text(name)
						.textStyle(.body2HighImportance)
						.foregroundColor(.app.gray1)
				}

				Spacer(minLength: 0)

				VStack(alignment: .trailing, spacing: 0) {
					HStack(spacing: .small2) {
						if guaranteedAmount != nil {
							Text("Estimated") // TODO:  string
								.textStyle(.body2Regular) // TODO:  unknown textStyle
						}
						//					Text(amount.formatted(.number))
						Text(amount.description)
							.textStyle(.secondaryHeader)
					}
					.foregroundColor(.app.gray1)
					.padding(.bottom, .small2)

					if let dollarAmount {
						//					Text(dollarAmount.formatted(.currency(code: "USD")))
						Text(dollarAmount.description)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}

					if let guaranteedAmount {
						//					Text("Guaranteed **\(guaranteedAmount.formatted(.number))**")
						Text("Guaranteed **\(guaranteedAmount.description)**")
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray2)
							.padding(.top, .small1)
					}
				}
				.padding(.vertical, .medium3)
			}
			.padding(.horizontal, .medium3)
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - TransactionReviewAccount_Preview
// struct TransactionReviewAccount_Preview: PreviewProvider {
//	static var previews: some View {
//		TransactionReviewAccount.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: TransactionReviewAccount()
//			)
//		)
//	}
// }
//
// extension TransactionReviewAccount.State {
//	public static let previewValue = Self()
// }
// #endif

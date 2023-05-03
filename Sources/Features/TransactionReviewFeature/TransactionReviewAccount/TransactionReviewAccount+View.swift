import FeaturePrelude

extension TransactionReviewAccounts.State {
	var viewState: TransactionReviewAccounts.ViewState {
		.init(showCustomizeGuarantees: showCustomizeGuarantees)
	}
}

extension TransactionReviewAccounts {
	public struct ViewState: Equatable {
		let showCustomizeGuarantees: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<TransactionReviewAccounts>

		public init(store: StoreOf<TransactionReviewAccounts>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Card(insetContents: true) {
					ForEachStore(
						store.scope(
							state: \.accounts,
							action: { .child(.account(id: $0, action: $1)) }
						),
						content: { TransactionReviewAccount.View(store: $0) }
					)

					if viewStore.showCustomizeGuarantees {
						Button(L10n.TransactionReview.customizeGuaranteesButtonTitle) {
							viewStore.send(.customizeGuaranteesTapped)
						}
						.textStyle(.body1Header)
						.foregroundColor(.app.blue2)
						.padding(.vertical, .small3)
					}
				}
			}
		}
	}
}

extension TransactionReviewAccount.State {
	var viewState: TransactionReviewAccount.ViewState {
		.init(account: account, details: transfers.elements, showApprovedMark: account.isApproved)
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	public struct ViewState: Equatable {
		let account: TransactionReview.Account
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
					SmallAccountCard(account: viewStore.account)

					ForEach(viewStore.details) { details in
						TransactionDetailsView(viewState: details)
					}
					.background(.app.gray5)
				}
			}
		}
	}
}

// MARK: - TransactionDetailsView
public struct TransactionDetailsView: View {
	public typealias ViewState = TransactionReview.Transfer

	public let viewState: ViewState

	public var body: some View {
		switch viewState.metadata.type {
		case .nonFungible:
			NFTView(name: viewState.metadata.name,
			        thumbnail: viewState.metadata.thumbnail)
		case .fungible:
			TransactionReviewTokenView(viewState: .init(
				name: viewState.metadata.name,
				thumbnail: viewState.thumbnail,
				amount: viewState.amount,
				guaranteedAmount: viewState.guarantee?.amount,
				fiatAmount: viewState.metadata.fiatAmount
			))
		case .none:
			EmptyView()
		}
	}

	struct NFTView: View {
		let name: String?
		let thumbnail: URL?

		var body: some View {
			HStack(spacing: .small1) {
				NFTThumbnail(thumbnail, size: .small)
					.padding(.vertical, .small1)

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
}

extension SmallAccountCard {
	public init(account: TransactionReview.Account) {
		switch account {
		case let .user(account):
			self.init(
				account: account
			)

		case let .external(accountAddress, _):
			self.init(
				L10n.TransactionReview.externalAccountName,
				identifiable: .address(.account(accountAddress)),
				gradient: .init(colors: [.app.gray2]),
				height: .guaranteeAccountLabelHeight
			)
		}
	}

	public init(account: Profile.Network.AccountForDisplay) {
		self.init(
			account.label.rawValue,
			identifiable: .address(.account(account.address)),
			gradient: .init(account.appearanceID),
			height: .guaranteeAccountLabelHeight
		)
	}
}

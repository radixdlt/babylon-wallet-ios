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
					AccountLabel(account: viewStore.account) {
						viewStore.send(.copyAddress)
					}

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
				thumbnail: viewState.metadata.thumbnail,
				amount: viewState.action.amount,
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
}

extension AccountLabel {
	public init(account: TransactionReview.Account, copyAction: (() -> Void)? = nil) {
		switch account {
		case let .user(account):
			self.init(
				account: account,
				copyAction: copyAction
			)

		case let .external(accountAddress, _):
			self.init(
				L10n.TransactionReview.externalAccountName,
				address: accountAddress.address,
				gradient: .init(colors: [.app.gray2]),
				copyAction: copyAction
			)
		}
	}

	public init(account: Profile.Network.AccountForDisplay, copyAction: (() -> Void)? = nil) {
		self.init(
			account.label.rawValue,
			address: account.address.address,
			gradient: .init(account.appearanceID),
			copyAction: copyAction
		)
	}
}

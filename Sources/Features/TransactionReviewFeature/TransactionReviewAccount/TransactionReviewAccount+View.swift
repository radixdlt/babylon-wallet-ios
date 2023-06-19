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
				Card {
					VStack(spacing: .small1) {
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
					.padding(.small1)
				}
			}
		}
	}
}

extension TransactionReviewAccount.State {
	var viewState: TransactionReviewAccount.ViewState {
		.init(account: account, transfers: transfers.elements, showApprovedMark: account.isApproved)
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	public struct ViewState: Equatable {
		let account: TransactionReview.Account
		let transfers: [TransactionReview.Transfer]
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

					ForEach(viewStore.transfers) { transfer in
						switch transfer {
						case let .fungible(fungibleTransfer):
							TransactionReviewTokenView(transfer: fungibleTransfer)
						case let .nonFungible(nonFungibleTransfer):
							TransferNFTView(transfer: nonFungibleTransfer)
						}
					}
					.background(.app.gray5)
				}
			}
		}
	}
}

extension TransactionReviewTokenView {
	init(transfer: TransactionReview.FungibleTransfer) {
		self.init(viewState: .init(
			name: transfer.symbol ?? transfer.name,
			thumbnail: transfer.isXRD ? .xrd : .known(transfer.thumbnail),
			amount: transfer.amount,
			guaranteedAmount: transfer.guarantee?.amount,
			fiatAmount: nil
		))
	}
}

extension TransferNFTView {
	init(transfer: TransactionReview.NonFungibleTransfer) {
		self.init(viewState: .init(
			resourceName: transfer.resourceName,
			tokenID: transfer.tokenID,
			tokenName: transfer.tokenName,
			thumbnail: transfer.thumbnail
		))
	}
}

//			let resourceMetadata = ResourceMetadata(
//				name: metadata?.symbol ?? metadata?.name ?? L10n.TransactionReview.unknown,
//				thumbnail: metadata?.iconURL,
//				type: addressKind.resourceType
//			)

// TransactionReviewTokenView(viewState: .init(
//	name: viewState.metadata.name,
//	thumbnail: viewState.thumbnail,
//	amount: viewState.amount,
//	guaranteedAmount: viewState.guarantee?.amount,
//	fiatAmount: viewState.metadata.fiatAmount
// ))

extension SmallAccountCard where Accessory == EmptyView {
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
}

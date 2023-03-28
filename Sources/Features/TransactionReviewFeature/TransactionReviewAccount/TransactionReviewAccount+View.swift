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
		switch account {
		case let .user(account):
			return .init(label: account.label.rawValue,
			             address: account.address.address,
			             gradient: .init(account.appearanceID),
			             details: transfers,
			             showApprovedMark: false)
		case let .external(accountAddress, approved):
			return .init(label: L10n.TransactionReview.externalAccountName,
			             address: accountAddress.address,
			             gradient: .init(colors: [.app.gray2]),
			             details: transfers,
			             showApprovedMark: approved)
		}
	}
}

// MARK: - TransactionReviewAccount.View
extension TransactionReviewAccount {
	public struct ViewState: Equatable {
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
					AccountLabel(
						viewStore.label,
						address: viewStore.address,
						gradient: viewStore.gradient
					) {
						viewStore.send(.copyAddress)
					}

					ForEach(viewStore.details, id: \.self) { details in
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
				guaranteedAmount: viewState.metadata.guarantee?.amount,
				dollarAmount: viewState.metadata.dollarAmount
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

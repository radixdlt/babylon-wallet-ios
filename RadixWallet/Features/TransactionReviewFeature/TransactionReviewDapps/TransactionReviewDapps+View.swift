import ComposableArchitecture
import SwiftUI

extension TransactionReviewDapps.State {
	var viewState: TransactionReviewDapps.ViewState {
		var dApps = knownDapps.map(\.knownDapp)
		if !unknownDapps.isEmpty {
			dApps.append(.unknown(unknownTitle))
		}
		return .init(rows: dApps)
	}
}

extension TransactionReview.DappEntity {
	fileprivate var knownDapp: TransactionReview.DappView.ViewState {
		.known(
			name: metadata.name ?? L10n.TransactionReview.unnamedDapp, // FIXME: ???
			thumbnail: metadata.iconURL,
			id: id,
			unauthorizedHint: isAuthorized ? nil : L10n.Common.unauthorized
		)
	}
}

// MARK: - TransactionReviewDapps.View
extension TransactionReviewDapps {
	public struct ViewState: Equatable {
		let rows: [TransactionReview.DappView.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewDapps>

		public init(store: StoreOf<TransactionReviewDapps>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .small2) {
					ForEach(viewStore.rows, id: \.self) { rowViewState in
						TransactionReview.DappView(viewState: rowViewState) { action in
							switch action {
							case let .knownDappTapped(id):
								viewStore.send(.dappTapped(id))
							case .unknownComponentsTapped:
								viewStore.send(.unknownsTapped)
							}
						}
					}
				}
			}
		}
	}
}

// MARK: - TransactionReview.DappView
extension TransactionReview {
	struct DappView: SwiftUI.View {
		enum ViewState: Hashable {
			case known(name: String, thumbnail: URL?, id: TransactionReview.DappEntity.ID, unauthorizedHint: String?)
			case unknown(String)
		}

		enum Action {
			case knownDappTapped(TransactionReview.DappEntity.ID)
			case unknownComponentsTapped
		}

		let viewState: ViewState
		let action: (Action) -> Void

		var body: some SwiftUI.View {
			switch viewState {
			case let .known(name, url, id, unauthorizedHint):
				Card {
					action(.knownDappTapped(id))
				} contents: {
					PlainListRow(title: name, subtitle: unauthorizedHint, accessory: nil) {
						Thumbnail(.dapp, url: url)
					}
				}

			case let .unknown(title):
				Card {
					action(.unknownComponentsTapped)
				} contents: {
					PlainListRow(title: title, accessory: nil) {
						Thumbnail(.dapp, url: nil)
					}
				}
			}
		}
	}
}

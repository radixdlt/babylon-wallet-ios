import ComposableArchitecture
import SwiftUI

extension TransactionReviewDappsUsed.State {
	var viewState: TransactionReviewDappsUsed.ViewState {
		var dApps = knownDapps.map(\.knownDapp)
		if !unknownDapps.isEmpty {
			dApps.append(.unknown(count: unknownDapps.count))
		}
		return .init(rows: dApps)
	}
}

extension TransactionReview.DappEntity {
	fileprivate var knownDapp: TransactionReviewDappsUsed.View.DappView.ViewState {
		.known(
			name: metadata.name ?? L10n.TransactionReview.unnamedDapp,
			thumbnail: metadata.iconURL,
			id: id,
			unauthorizedHint: isAuthorized ? nil : L10n.Common.unauthorized
		)
	}
}

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewDappsUsed {
	public struct ViewState: Equatable {
		let rows: [View.DappView.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewDappsUsed>
		let isExpanded: Bool

		public init(store: StoreOf<TransactionReviewDappsUsed>, isExpanded: Bool) {
			self.store = store
			self.isExpanded = isExpanded
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: .small2) {
					ExpandableTransactionHeading(heading: .usingDapps, isExpanded: isExpanded) {
						viewStore.send(.expandTapped)
					}

					if isExpanded {
						VStack(spacing: .small2) {
							ForEach(viewStore.rows, id: \.self) { rowViewState in
								DappView(viewState: rowViewState) { action in
									switch action {
									case let .knownDappTapped(id):
										viewStore.send(.dappTapped(id))
									case .unknownComponentsTapped:
										viewStore.send(.unknownComponentsTapped)
									}
								}
							}
						}
						.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
				.animation(.easeInOut, value: isExpanded)
			}
		}

		struct DappView: SwiftUI.View {
			enum ViewState: Hashable {
				case known(name: String, thumbnail: URL?, id: TransactionReview.DappEntity.ID, unauthorizedHint: String?)
				case unknown(count: Int)
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
							DappThumbnail(.known(url))
						}
					}

				case let .unknown(count):
					Card {
						action(.unknownComponentsTapped)
					} contents: {
						PlainListRow(title: L10n.TransactionReview.unknownComponents(count), accessory: nil) {
							DappThumbnail(.unknown)
						}
					}
				}
			}
		}
	}
}

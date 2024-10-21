import ComposableArchitecture
import SwiftUI

extension InteractionReviewDapps.State {
	var viewState: InteractionReviewDapps.ViewState {
		var dApps = knownDapps.map(\.knownDapp)
		if !unknownDapps.isEmpty {
			dApps.append(.unknown(unknownTitle))
		}
		return .init(rows: dApps)
	}
}

extension InteractionReview.DappEntity {
	fileprivate var knownDapp: InteractionReview.DappView.ViewState {
		.known(
			name: metadata.name,
			thumbnail: metadata.iconURL,
			id: id
		)
	}
}

// MARK: - InteractionReviewDapps.View
extension InteractionReviewDapps {
	struct ViewState: Equatable {
		let rows: [InteractionReview.DappView.ViewState]
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReviewDapps>

		init(store: StoreOf<InteractionReviewDapps>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .small2) {
					ForEach(viewStore.rows, id: \.self) { rowViewState in
						InteractionReview.DappView(viewState: rowViewState) { action in
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

// MARK: - InteractionReview.DappView
extension InteractionReview {
	struct DappView: SwiftUI.View {
		enum ViewState: Hashable {
			case known(name: String?, thumbnail: URL?, id: InteractionReview.DappEntity.ID)
			case unknown(String)
		}

		enum Action {
			case knownDappTapped(InteractionReview.DappEntity.ID)
			case unknownComponentsTapped
		}

		let viewState: ViewState
		let action: (Action) -> Void

		var body: some SwiftUI.View {
			switch viewState {
			case let .known(name, url, id):
				Card {
					action(.knownDappTapped(id))
				} contents: {
					PlainListRow(title: name, accessory: nil) {
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

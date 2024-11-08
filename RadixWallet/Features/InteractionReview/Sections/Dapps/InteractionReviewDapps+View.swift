import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReviewDapps.View
extension InteractionReviewDapps {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReviewDapps>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .small2) {
					ForEach(store.rows, id: \.self) { rowViewState in
						InteractionReview.DappView(viewState: rowViewState) { action in
							switch action {
							case let .knownDappTapped(id):
								store.send(.view(.dappTapped(id)))
							case .unknownComponentsTapped:
								store.send(.view(.unknownsTapped))
							}
						}
					}
				}
			}
		}
	}
}

extension InteractionReviewDapps.State {
	var rows: [InteractionReview.DappView.ViewState] {
		var dApps = knownDapps.map(\.knownDapp)
		if !unknownDapps.isEmpty {
			dApps.append(.unknown(unknownTitle))
		}
		return dApps
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

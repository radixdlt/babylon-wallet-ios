import ComposableArchitecture
import SwiftUI
extension TransactionReviewDappsUsed.State {
	var viewState: TransactionReviewDappsUsed.ViewState {
		var dApps = knownDapps.map(\.knownDapp)
		if unknownDapps > 0 {
			dApps.append(.unknown(count: unknownDapps))
		}
		return .init(rows: dApps)
	}
}

extension TransactionReview.DappEntity {
	fileprivate var knownDapp: TransactionReviewDappsUsed.View.DappView.ViewState {
		.known(
			name: metadata.name ?? L10n.TransactionReview.unnamedDapp,
			thumbnail: metadata.iconURL,
			id: id
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
					Button {
						viewStore.send(.expandTapped)
					} label: {
						Heading(isExpanded: isExpanded)
					}

					if isExpanded {
						VStack(spacing: .small2) {
							ForEach(viewStore.rows, id: \.self) { rowViewState in
								DappView(viewState: rowViewState) { id in
									viewStore.send(.dappTapped(id))
								}
							}
						}
						.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
				.animation(.easeInOut, value: isExpanded)
			}
		}

		struct Heading: SwiftUI.View {
			let isExpanded: Bool

			var body: some SwiftUI.View {
				HStack(spacing: .small3) {
					Image(asset: AssetResource.transactionReviewDapps)
					Text(L10n.TransactionReview.usingDappsHeading)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Image(asset: isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
						.renderingMode(.original)
					Spacer()
				}
			}
		}

		struct DappView: SwiftUI.View {
			enum ViewState: Hashable {
				case known(name: String, thumbnail: URL?, id: TransactionReview.DappEntity.ID)
				case unknown(count: Int)
			}

			let viewState: ViewState
			let action: (TransactionReview.DappEntity.ID) -> Void

			var body: some SwiftUI.View {
				switch viewState {
				case let .known(name, url, id):
					Card {
						action(id)
					} contents: {
						PlainListRow(title: name, accessory: nil) {
							DappThumbnail(.known(url))
						}
					}

				case let .unknown(count):
					Card {
						// action(id)
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

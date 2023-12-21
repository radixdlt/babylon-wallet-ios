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
				VStack(spacing: .medium2) {
					Button {
						viewStore.send(.expandTapped)
					} label: {
						HeadingLabel(isExpanded: isExpanded)
					}
					.padding(.trailing, .medium3)

					if isExpanded {
						VStack(spacing: .small2) {
							ForEach(viewStore.rows, id: \.self) { rowViewState in
								DappView(viewState: rowViewState) { id in
									viewStore.send(.dappTapped(id))
								}
								.background(.app.gray5)
							}
						}
						.transition(.opacity.combined(with: .scale(scale: 0.95)))
					}
				}
				.animation(.easeInOut, value: isExpanded)
			}
		}

		struct HeadingLabel: SwiftUI.View {
			let isExpanded: Bool

			var body: some SwiftUI.View {
				HStack(spacing: .small3) {
					Text(L10n.TransactionReview.usingDappsHeading)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray2)
						.textCase(.uppercase)
					Image(asset: isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
						.renderingMode(.original)
				}
			}
		}

		struct DappView: SwiftUI.View {
			private let dAppBoxWidth: CGFloat = 190

			enum ViewState: Hashable {
				case known(name: String, thumbnail: URL?, id: TransactionReview.DappEntity.ID)
				case unknown(count: Int)
			}

			let viewState: ViewState
			let action: (TransactionReview.DappEntity.ID) -> Void

			var body: some SwiftUI.View {
				Card {
					HStack(spacing: 0) {
						switch viewState {
						case let .known(name, url, id):
							Button {
								action(id)
							} label: {
								HStack(spacing: 0) {
									DappThumbnail(.known(url), size: .smaller)
										.padding(.trailing, .small2)
									Text(name)
										.textStyle(.body1Header)
										.foregroundColor(.app.gray1)
										.lineLimit(2)
								}
							}
						case let .unknown(count):
							DappThumbnail(.unknown, size: .smaller)
								.padding(.trailing, .small2)
							Text(L10n.TransactionReview.unknownComponents(count))
								.lineLimit(2)
						}
						Spacer()
					}
					.frame(minWidth: .infinity, minHeight: .standardButtonHeight)
				}
			}
		}
	}
}

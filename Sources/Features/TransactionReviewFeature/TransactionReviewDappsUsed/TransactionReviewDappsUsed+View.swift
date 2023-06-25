import FeaturePrelude

extension TransactionReviewDappsUsed.State {
	var viewState: TransactionReviewDappsUsed.ViewState {
		let knownDapps = dApps.compactMap(\.knownDapp)
		let unknownDappCount = dApps.count - knownDapps.count

		if unknownDappCount == 0 {
			return .init(rows: knownDapps)
		} else {
			return .init(rows: knownDapps + [.unknown(count: unknownDappCount)])
		}
	}
}

extension TransactionReview.DappEntity {
	fileprivate var knownDapp: TransactionReviewDappsUsed.View.DappView.ViewState? {
		guard let metadata else { return nil }
		return .known(
			name: metadata.name ?? L10n.TransactionReview.unknown,
			thumbnail: metadata.thumbnail,
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
				VStack(alignment: .trailing, spacing: .medium2) {
					Button {
						viewStore.send(.expandTapped)
					} label: {
						HeadingLabel(isExpanded: isExpanded)
					}
					.background(.app.gray5)
					.padding(.trailing, .medium3)

					if isExpanded {
						VStack(spacing: .small2) {
							ForEach(viewStore.rows, id: \.self) { rowViewState in
								DappView(viewState: rowViewState) { id in
									viewStore.send(.dappTapped(id))
								}
							}
						}
						.transition(.opacity.combined(with: .scale(scale: 0.95)))
						.background(.app.gray5)
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
									.lineLimit(2)
							}
						}
					case let .unknown(count):
						DappThumbnail(.unknown, size: .smaller)
							.padding(.trailing, .small2)
						Text(L10n.TransactionReview.unknownComponents(count))
							.lineLimit(2)
					}

					Spacer(minLength: 0)
				}
				.textStyle(.body2HighImportance)
				.foregroundColor(.app.gray2)
				.multilineTextAlignment(.leading)
				.padding(.small2)
				.frame(width: dAppBoxWidth)
				.background {
					RoundedRectangle(cornerRadius: .small2)
						.stroke(.app.gray3, style: .transactionReview)
				}
			}
		}
	}
}

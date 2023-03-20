import FeaturePrelude

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewDappsUsed {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewDappsUsed>
		let isExpanded: Bool

		public init(store: StoreOf<TransactionReviewDappsUsed>, isExpanded: Bool) {
			self.store = store
			self.isExpanded = isExpanded
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.dApps, send: { .view($0) }) { viewStore in
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
							ForEach(viewStore.state) { dApp in
								Button {
									viewStore.send(.dappTapped(dApp.id))
								} label: {
									DappView(thumbnail: dApp.thumbnail, name: dApp.name, description: dApp.description)
								}
							}
						}
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
					// Image(asset: viewStore.isExpanded ? AssetResource.chevronUp : AssetResource.chevronDown)
					Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
				}
			}
		}

		struct DappView: SwiftUI.View {
			private let dAppBoxWidth: CGFloat = 190

			let thumbnail: URL?
			let name: String
			let description: String?

			var body: some SwiftUI.View {
				HStack(spacing: 0) {
					DappPlaceholder(size: .smaller)
						.padding(.trailing, .small2)

					VStack(alignment: .leading, spacing: .small3) {
						Text(name)

						if let description {
							Text(description)
						}
					}
					.lineLimit(1)
					.textStyle(.body2HighImportance)
					.foregroundColor(.app.gray2)

					Spacer(minLength: 0)
				}
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

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - TransactionReviewDappsUsed_Preview
// struct TransactionReviewDappsUsed_Preview: PreviewProvider {
//	static var previews: some View {
//		TransactionReviewDappsUsed.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: TransactionReviewDappsUsed()
//			)
//		)
//	}
// }
//
// extension TransactionReviewDappsUsed.State {
//	public static let previewValue = Self()
// }
// #endif

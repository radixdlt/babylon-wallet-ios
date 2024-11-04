import SwiftUI

extension InteractionReview {
	struct VisibleHeaderView<Content: View>: SwiftUI.View {
		let kind: InteractionReview.Kind
		let metadata: DappMetadata.Ledger?
		let content: Content

		init(
			kind: InteractionReview.Kind,
			metadata: DappMetadata.Ledger?,
			@ViewBuilder content: () -> Content
		) {
			self.kind = kind
			self.metadata = metadata
			self.content = content()
		}

		@SwiftUI.State private var showNavigationTitle = false

		private let coordSpace: String = "InteractionReviewCoordSpace"
		private let navTitleID: String = "InteractionReview.title"
		private let showTitleHysteresis: CGFloat = .small3

		var body: some View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: .zero) {
					header

					content
				}
			}
			.coordinateSpace(name: coordSpace)
			.onPreferenceChange(PositionsPreferenceKey.self) { positions in
				guard let offset = positions[navTitleID]?.maxY else {
					showNavigationTitle = true
					return
				}
				if showNavigationTitle, offset > showTitleHysteresis {
					showNavigationTitle = false
				} else if !showNavigationTitle, offset < 0 {
					showNavigationTitle = true
				}
			}
			.toolbar {
				ToolbarItem(placement: .principal) {
					if showNavigationTitle {
						navigationTitle
					}
				}
			}
		}

		private var header: some SwiftUI.View {
			Common.HeaderView(
				kind: kind,
				name: metadata?.name?.rawValue,
				thumbnail: metadata?.thumbnail
			)
			.measurePosition(navTitleID, coordSpace: coordSpace)
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium3)
			.background {
				switch kind {
				case .transaction:
					JaggedEdge(shadowColor: InteractionReview.shadowColor, isTopEdge: true)
				case .preAuthorization:
					EmptyView()
				}
			}
		}

		private var navigationTitle: some SwiftUI.View {
			VStack(spacing: .zero) {
				Text(title)
					.textStyle(.body2Header)
					.foregroundColor(.app.gray1)

				if let dAppName = metadata?.name?.rawValue {
					Text(L10n.PreAuthorizationReview.subtitle(dAppName))
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
			}
		}

		private var title: String {
			switch kind {
			case .transaction:
				L10n.TransactionReview.title
			case .preAuthorization:
				L10n.PreAuthorizationReview.title
			}
		}
	}
}

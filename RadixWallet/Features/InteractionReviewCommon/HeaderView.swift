import SwiftUI

extension InteractionReviewCommon {
	struct HeaderView: View {
		let kind: Kind
		let name: String?
		let thumbnail: URL?

		var body: some View {
			VStack(alignment: .leading, spacing: .small2) {
				Text(title)
					.textStyle(.sheetTitle)
					.lineLimit(2)
					.multilineTextAlignment(.leading)
					.foregroundColor(.app.gray1)

				if showBottom {
					HStack(spacing: .small2) {
						if let thumbnail {
							Thumbnail(.dapp, url: thumbnail, size: .smallest)
						}
						Text(subtitle)
							.textStyle(.body2HighImportance)
							.foregroundColor(.app.gray1)
					}
				}
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}

		private var title: String {
			switch kind {
			case .transaction:
				L10n.TransactionReview.title
			case .preAuthorization:
				"Review Your Pre-Authorization"
			}
		}

		private var subtitle: String? {
			guard let name else { return nil }
			switch kind {
			case .transaction:
				return L10n.TransactionReview.proposingDappSubtitle(name)
			case .preAuthorization:
				return "Proposed by \(name)"
			}
		}

		private var showBottom: Bool {
			thumbnail != nil || name != nil
		}
	}
}

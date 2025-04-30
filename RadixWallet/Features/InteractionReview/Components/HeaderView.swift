import SwiftUI

extension InteractionReview {
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
					.foregroundColor(.primaryText)

				if showBottom {
					HStack(spacing: .small2) {
						if let thumbnail {
							Thumbnail(.dapp, url: thumbnail, size: .smallest)
						}
						Text(subtitle)
							.textStyle(.body2HighImportance)
							.foregroundColor(.primaryText)
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
				L10n.PreAuthorizationReview.title
			}
		}

		private var subtitle: String? {
			guard let name else { return nil }
			return L10n.InteractionReview.subtitle(name)
		}

		private var showBottom: Bool {
			thumbnail != nil || name != nil
		}
	}
}

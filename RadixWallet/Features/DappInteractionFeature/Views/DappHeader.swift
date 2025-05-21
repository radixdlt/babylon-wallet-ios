import ComposableArchitecture
import SwiftUI

struct DappHeader: View {
	let thumbnail: URL?
	let title: String
	/// If given as markdown, italics will be shown as plain text in the color `.primaryText`
	let subtitle: String

	var body: some View {
		VStack(spacing: .medium2) {
			Thumbnail(.dapp, url: thumbnail, size: .medium)

			Text(title)
				.foregroundColor(.primaryText)
				.lineSpacing(0)
				.textStyle(.sheetTitle)

			Text(markdown: subtitle, emphasizedColor: .primaryText)
				.foregroundColor(.secondaryText)
				.textStyle(.secondaryHeader)
		}
		.multilineTextAlignment(.center)
		.padding(.bottom, .small2)
	}
}

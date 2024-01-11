import ComposableArchitecture
import SwiftUI

struct DappHeader: View {
	let thumbnail: URL?
	let title: String
	/// If given as markdown, italics will be shown as plain text in the color `.app.gray1`
	let subtitle: String

	var body: some View {
		VStack(spacing: .medium3) {
			DappThumbnail(.known(thumbnail), size: .medium)

			Text(title)
				.foregroundColor(.app.gray1)
				.lineSpacing(0)
				.textStyle(.sheetTitle)

			Text(markdown: subtitle, italicsColor: .app.gray1)
				.foregroundColor(.app.gray2)
				.textStyle(.secondaryHeader)
		}
		.multilineTextAlignment(.center)
		.padding(.bottom, .small2)
	}
}

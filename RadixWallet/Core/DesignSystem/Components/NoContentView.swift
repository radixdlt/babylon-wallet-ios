import SwiftUI

struct NoContentView: SwiftUI.View {
	let text: String
	init(_ text: String) {
		self.text = text
	}

	var body: some SwiftUI.View {
		Text(text)
			.foregroundColor(.secondaryText)
			.padding(.large2)
			.background(.secondaryBackground)
			.cornerRadius(.small1)
	}
}

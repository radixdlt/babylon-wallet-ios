import SwiftUI

struct NoContentView: SwiftUI.View {
	let text: String
	init(_ text: String) {
		self.text = text
	}

	var body: some SwiftUI.View {
		Text(text)
			.foregroundColor(.app.gray2)
			.padding(.large2)
			.background(.app.gray5)
			.cornerRadius(.small1)
	}
}

import SwiftUI

public struct NoContentView: SwiftUI.View {
	public let text: String
	public init(_ text: String) {
		self.text = text
	}

	public var body: some SwiftUI.View {
		Text(text)
			.foregroundColor(.app.gray2)
			.padding(.large1)
			.background(.app.gray5)
			.cornerRadius(.small1)
	}
}

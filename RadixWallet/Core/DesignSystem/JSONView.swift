import JSONPreview

// MARK: - JSONView
public struct JSONView: SwiftUI.View {
	let jsonString: String
	public init(jsonString: String) {
		self.jsonString = jsonString
	}

	public var body: some View {
		UIKitJSONView(jsonString: jsonString)
			.padding(.leading, -60) // we hide the "line number" view on the left which eats up precious widdth,zoo
	}
}

// MARK: - UIKitJSONView
@MainActor
struct UIKitJSONView: UIViewRepresentable {
	let jsonPreview: JSONPreview
	init(jsonString: String) {
		let jsonPreview = JSONPreview()
		jsonPreview.preview(jsonString)
		self.jsonPreview = jsonPreview
	}

	func makeUIView(context: Context) -> JSONPreview {
		jsonPreview
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}

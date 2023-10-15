
#if canImport(UIKit)
#endif

// MARK: - JSONView
public struct JSONView: SwiftUI.View {
	let jsonString: String
	public init(jsonString: String) {
		self.jsonString = jsonString
	}

	public var body: some View {
		#if canImport(UIKit)
		UIKitJSONView(jsonString: jsonString)
			.padding(.leading, -60) // we hide the "line number" view on the left which eats up precious widdth,zoo
		#else
		Text("`\(jsonString)`")
		#endif
	}
}

#if canImport(UIKit)
@MainActor
struct UIKitJSONView: UIViewRepresentable {
	let jsonPreview: JSONPreview
	init(jsonString: String) {
		let jsonPreview = JSONPreview()
		jsonPreview.preview(jsonString, style: .default)
		self.jsonPreview = jsonPreview
	}

	func makeUIView(context: Context) -> JSONPreview {
		jsonPreview
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}
#endif // canImport(UIKit)

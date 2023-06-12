import Foundation

#if canImport(UIKit)
import JSONPreview
import UIKit
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
		var style = HighlightStyle.default
		jsonPreview.preview(jsonString, style: style)
		self.jsonPreview = jsonPreview
	}

	func makeUIView(context: Context) -> JSONPreview {
		jsonPreview
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}
#endif // canImport(UIKit)

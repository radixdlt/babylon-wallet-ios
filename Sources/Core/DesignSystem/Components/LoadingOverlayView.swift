import SwiftUI

public extension View {
	func presentsLoadingViewOverlay() -> some View {
		overlayPreferenceValue(LoadingContextKey.self, alignment: .center) { context in
			if case let .global(text) = context {
				LoadingOverlayView(text)
			}
		}
	}
}

// MARK: - LoadingOverlayView
private struct LoadingOverlayView: View {
	private let text: String?
	public init(_ text: String?) {
		self.text = text
	}

	public var body: some View {
		ZStack {
			Color.app.gray2
				.cornerRadius(.small1)

			VStack {
				LoadingView()
				if let text {
					Text(text)
						.lineLimit(2)
						.textStyle(.body1Regular)
						.foregroundColor(.app.white)
				}
			}
			.padding()
		}
		.frame(width: 180, height: 180)
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct LoadingOverlayView_Preview: PreviewProvider {
	static var previews: some View {
		LoadingOverlayView("Connecting")
	}
}
#endif

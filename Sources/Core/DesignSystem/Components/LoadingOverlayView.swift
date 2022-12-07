import SwiftUI

// MARK: - LoadingOverlayView
public struct LoadingOverlayView: View {
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

public extension View {
	func overlayLoadingView() -> some View {
		overlayPreferenceValue(LoadingStateKey.self, alignment: .center) { value in
			if value.isLoading, let configuration = value.configuration {
				switch configuration {
				case let .global(text):
					LoadingOverlayView(text)
				}
			}
		}
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

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
						.textStyle(.body1Regular)
						.foregroundColor(.app.white)
				}
			}
			.frame(width: 100, height: 100)
		}
		.frame(width: 170, height: 170)
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

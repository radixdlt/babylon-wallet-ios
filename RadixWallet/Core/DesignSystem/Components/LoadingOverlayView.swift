
extension View {
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
	init(_ text: String?) {
		self.text = text
	}

	var body: some View {
		ZStack {
			VStack(spacing: .medium2) {
				LoadingView().frame(width: 100, height: 100)
				if let text {
					Text(text)
						.lineLimit(nil)
						.textStyle(.body1Regular)
						.foregroundColor(.primaryText)
						.multilineTextAlignment(.center)
				}
			}
			.padding(.medium2)
		}
		.frame(minWidth: 180)
		// .background(Color.tertiaryBackground.cornerRadius(.small1))
		// .frame(maxWidth: 240)
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct LoadingOverlayView_Preview: PreviewProvider {
	static var previews: some View {
		VStack {
			LoadingOverlayView("Loading...")
			LoadingOverlayView("Preparing transaction...")
			LoadingOverlayView("Doing something very long to describe...")
		}
	}
}
#endif

extension View {
	func withDottedCircleOverlay() -> some View {
		self
			.padding(.small3)
			.overlay {
				Circle()
					.stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
					.foregroundColor(.app.gray3)
			}
	}

	func radixToolbar(title: String, alwaysVisible: Bool = true, closeAction: (() -> Void)? = nil) -> some View {
		toolbar {
			ToolbarItem(placement: .principal) {
				Text(title)
					.foregroundColor(.app.gray1)
					.textStyle(.body1Header)
			}

			if let closeAction {
				ToolbarItem(placement: .navigationBarLeading) {
					CloseButton(action: closeAction)
				}
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.app.background, for: .navigationBar)
		.toolbarBackground(alwaysVisible ? .visible : .automatic, for: .navigationBar)
	}

	func eraseToAnyView() -> AnyView {
		AnyView(self)
	}

	/// Embeds the view on a `Button` when an action is provided.
	/// Otherwise returns the same view unmodified.
	func embedInButton(when action: (() -> Void)?) -> some View {
		Group {
			if let action {
				Button(action: action) {
					self
				}
			} else {
				self
			}
		}
	}
}

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

	func setUpNavigationBar(title: String) -> some View {
		self
			.navigationTitle(title)
			.navigationBarTitleDisplayMode(.inline)
	}

	func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
}

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
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(title)
						.foregroundColor(.app.gray1)
						.textStyle(.secondaryHeader)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.app.background, for: .navigationBar)
			.toolbarBackground(.visible, for: .navigationBar)
	}

	func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
}

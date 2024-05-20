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

	func radixToolbar(title: String, alwaysVisible: Bool = true) -> some View {
		self
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1Header)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.app.background, for: .navigationBar)
			.toolbarBackground(alwaysVisible ? .visible : .automatic, for: .navigationBar)
	}

	func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
}

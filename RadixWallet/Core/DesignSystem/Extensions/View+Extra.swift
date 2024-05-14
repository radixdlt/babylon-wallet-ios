extension View {
	func withDottedCircleOverlay() -> some View {
		padding(.small3)
			.overlay {
				Circle()
					.stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
					.foregroundColor(.app.gray3)
			}
	}

	func radixNavigationBar(title: String) -> some View {
		toolbar {
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

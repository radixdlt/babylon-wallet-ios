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

	func setUpNavigationBar(title: String, includeBackground: Bool = true) -> some View {
		self
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text(title)
						.foregroundColor(.app.gray1)
						.textStyle(.body1Header)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.applyIf(includeBackground) {
				$0.toolbarBackground(.app.background, for: .navigationBar)
					.toolbarBackground(.visible, for: .navigationBar)
			}
	}

	func eraseToAnyView() -> AnyView {
		AnyView(self)
	}
}

// MARK: - Apply
extension View {
	/// Applies `modifier` if given `condition` is met.
	@ViewBuilder
	func applyIf<Modifier>(_ condition: Bool, @ViewBuilder modifier: () -> Modifier) -> some View where Modifier: ViewModifier {
		if condition {
			self.modifier(modifier())
		} else {
			self
		}
	}

	/// Applies `transform` if given `condition` is met.
	@ViewBuilder
	func applyIf<Content>(_ condition: Bool, @ViewBuilder transform: (Self) -> Content) -> some View where Content: View {
		if condition {
			transform(self)
		} else {
			self
		}
	}
}

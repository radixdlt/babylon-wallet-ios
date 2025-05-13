extension View {
	func withDottedCircleOverlay() -> some View {
		self
			.padding(.small3)
			.overlay {
				Circle()
					.stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
					.foregroundColor(.iconTertiary)
			}
	}

	func radixToolbar(title: String, alwaysVisible: Bool = true, closeAction: (() -> Void)? = nil) -> some View {
		toolbar {
			ToolbarItem(placement: .principal) {
				Text(title)
					.foregroundColor(Color.primaryText)
					.textStyle(.body1Header)
			}

			if let closeAction {
				ToolbarItem(placement: .navigationBarLeading) {
					CloseButton(action: closeAction)
				}
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(Color.primaryBackground, for: .navigationBar)
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

	/// Applies the given transform when the given conditions is met.
	@ViewBuilder
	func applyIf(_ condition: Bool, @ViewBuilder transform: (Self) -> some View) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}

	/// Sets the List section spacing if possible.
	@available(iOS, deprecated: 18.0, message: "Should use native `listSectionSpacing` once iOS 16 is no longer supported.")
	func withListSectionSpacing(_ spacing: CGFloat) -> some SwiftUI.View {
		Group {
			if #available(iOS 17.0, *) {
				self
					.listSectionSpacing(spacing)
			} else {
				self
			}
		}
	}

	/// Makes the given view scrollable, while adding some space into the bottom if there is more height available.
	func scrollableWithBottomSpacer() -> some View {
		GeometryReader { proxy in
			WithPerceptionTracking {
				ScrollView(showsIndicators: false) {
					VStack(spacing: .zero) {
						self

						Spacer()
					}
					.frame(minHeight: proxy.size.height)
				}
				.frame(width: proxy.size.width)
			}
		}
	}
}

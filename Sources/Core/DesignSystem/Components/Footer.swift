import SwiftUI

extension View {
	@ViewBuilder
	public func footer<Content: View>(visible: Bool = true, @ViewBuilder _ content: () -> Content) -> some View {
		if visible {
			modifier(FooterModifier(footerContent: content))
		} else {
			self
		}
	}
}

// MARK: - FooterModifier
private struct FooterModifier<FooterContent: View>: ViewModifier {
	@ViewBuilder
	let footerContent: FooterContent

	func body(content: Content) -> some View {
		content
			.safeAreaInset(edge: .bottom, spacing: 0) {
				VStack(spacing: 0) {
					Separator()
					VStack {
						footerContent
					}
					.padding(.medium3)
				}
				.background(Color.app.background)
			}
	}
}

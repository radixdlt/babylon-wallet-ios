import SwiftUI

extension View {
	public func footer<Content: View>(shouldShow: Bool = true, @ViewBuilder _ content: () -> Content) -> some View {
		self.modifier(FooterModifier(shouldShow: shouldShow, footerContent: content))
	}
}

// MARK: - FooterModifier
private struct FooterModifier<FooterContent: View>: ViewModifier {
	let shouldShow: Bool
	@ViewBuilder
	let footerContent: FooterContent

	func body(content: Content) -> some View {
		if shouldShow {
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
}

import SwiftUI

extension View {
	public func footer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
		self.modifier(FooterModifier(footerContent: content))
	}
}

// MARK: - FooterModifier
struct FooterModifier<FooterContent: View>: ViewModifier {
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

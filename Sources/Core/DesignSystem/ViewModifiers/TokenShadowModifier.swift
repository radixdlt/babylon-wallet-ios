import SwiftUI

// MARK: - TokenRowShadow
struct TokenRowShadow: ViewModifier {
	let condition: Bool?

	func body(content: Content) -> some View {
		content
			.shadow(color: condition ?? false ? .clear : .app.shadowBlack, radius: .small2, x: .zero, y: .small2)
	}
}

extension View {
	public func tokenRowShadow(condition: Bool? = nil) -> some View {
		modifier(TokenRowShadow(condition: condition))
	}
}

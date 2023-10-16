#if os(iOS)
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
	public func navigationBarInlineTitleFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarInlineTitleFontModifier(uiFont: uiFont))
	}

	public func navigationBarLargeTitleFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarLargeTitleFontModifier(uiFont: uiFont))
	}
}

// MARK: - NavigationBarInlineTitleFontModifier
struct NavigationBarInlineTitleFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspect(
			.navigationStack, on: .iOS(.v16...),
			scope: [.receiver, .ancestor]
		) { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.titleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.titleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
		}
	}
}

// MARK: - NavigationBarLargeTitleFontModifier
struct NavigationBarLargeTitleFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspect(
			.navigationStack, on: .iOS(.v16...),
			scope: [.receiver, .ancestor]
		) { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.largeTitleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.largeTitleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
		}
	}
}
#endif // iOS

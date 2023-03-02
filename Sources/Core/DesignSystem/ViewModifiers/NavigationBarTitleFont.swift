#if os(iOS)
import Introspect
import SwiftUI

extension View {
	public func navigationBarInlineTitleFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarInlineTitleFontModifier(uiFont: uiFont))
	}

	public func navigationBarLargeTitleFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarLargeTitleFontModifier(uiFont: uiFont))
	}
}

struct NavigationBarInlineTitleFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.titleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.titleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
		}
	}
}

struct NavigationBarLargeTitleFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.largeTitleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.largeTitleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
		}
	}
}
#endif

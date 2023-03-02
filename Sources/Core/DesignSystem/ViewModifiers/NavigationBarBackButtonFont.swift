#if os(iOS)
import Introspect
import SwiftUI

extension View {
	public func navigationBarBackButtonFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarBackButtonFontModifier(uiFont: uiFont))
	}
}

struct NavigationBarBackButtonFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
		}
	}
}
#endif

#if os(iOS)
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
	public func navigationBarBackButtonFont(_ uiFont: UIFont) -> some View {
		self.modifier(NavigationBarBackButtonFontModifier(uiFont: uiFont))
	}
}

struct NavigationBarBackButtonFontModifier: ViewModifier {
	let uiFont: UIFont

	func body(content: Content) -> some View {
		content.introspect(.navigationStack, on: .iOS(.v16...), scope: [.receiver, .ancestor]) { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.standardAppearance.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.compactAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.scrollEdgeAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
			navigationBar.compactScrollEdgeAppearance?.backButtonAppearance.normal.titleTextAttributes[.font] = uiFont
		}
	}
}
#endif

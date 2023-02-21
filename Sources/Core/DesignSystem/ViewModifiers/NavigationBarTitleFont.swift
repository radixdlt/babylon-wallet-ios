import Introspect
import Resources
import SwiftUI

extension View {
	public func navigationBarTitleFont(
		_ uiFont: UIFont,
		for displayMode: NavigationBarItem.TitleDisplayMode = .automatic
	) -> some View {
		#if os(iOS)
		self.modifier(NavigationBarTitleFontModifier(uiFont: uiFont, displayMode: displayMode))
		#else
		self
		#endif
	}
}

#if os(iOS)
struct NavigationBarTitleFontModifier: ViewModifier {
	let uiFont: UIFont
	let displayMode: NavigationBarItem.TitleDisplayMode

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			switch displayMode {
			case .automatic:
				setNavigationBarInlineTitleFont(navigationBar, uiFont)
				setNavigationBarLargeTitleFont(navigationBar, uiFont)
			case .inline:
				setNavigationBarInlineTitleFont(navigationBar, uiFont)
			case .large:
				setNavigationBarLargeTitleFont(navigationBar, uiFont)
			@unknown default:
				break
			}
		}
	}

	@MainActor
	func setNavigationBarInlineTitleFont(_ navigationBar: UINavigationBar, _ uiFont: UIFont) {
		navigationBar.standardAppearance.titleTextAttributes[.font] = uiFont
		navigationBar.compactAppearance?.titleTextAttributes[.font] = uiFont
		navigationBar.scrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
		navigationBar.compactScrollEdgeAppearance?.titleTextAttributes[.font] = uiFont
	}

	@MainActor
	func setNavigationBarLargeTitleFont(_ navigationBar: UINavigationBar, _ uiFont: UIFont) {
		navigationBar.standardAppearance.largeTitleTextAttributes[.font] = uiFont
		navigationBar.compactAppearance?.largeTitleTextAttributes[.font] = uiFont
		navigationBar.scrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
		navigationBar.compactScrollEdgeAppearance?.largeTitleTextAttributes[.font] = uiFont
	}
}
#endif

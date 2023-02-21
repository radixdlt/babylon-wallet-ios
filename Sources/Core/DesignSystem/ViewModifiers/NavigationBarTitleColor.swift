import Introspect
import SwiftUI

extension View {
	public func navigationBarTitleColor(
		_ color: Color, for displayMode: NavigationBarItem.TitleDisplayMode = .automatic
	) -> some View {
		#if os(iOS)
		self.modifier(NavigationBarTitleColorModifier(color: color, displayMode: displayMode))
		#else
		self
		#endif
	}
}

#if os(iOS)
struct NavigationBarTitleColorModifier: ViewModifier {
	let color: Color
	let displayMode: NavigationBarItem.TitleDisplayMode

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			let uiColor = UIColor(color)
			switch displayMode {
			case .automatic:
				setNavigationBarInlineTitleColor(navigationBar, uiColor)
				setNavigationBarLargeTitleColor(navigationBar, uiColor)
			case .inline:
				setNavigationBarInlineTitleColor(navigationBar, uiColor)
			case .large:
				setNavigationBarLargeTitleColor(navigationBar, uiColor)
			@unknown default:
				break
			}
		}
	}

	@MainActor
	func setNavigationBarInlineTitleColor(_ navigationBar: UINavigationBar, _ uiColor: UIColor) {
		navigationBar.standardAppearance.titleTextAttributes[.foregroundColor] = uiColor
		navigationBar.compactAppearance?.titleTextAttributes[.foregroundColor] = uiColor
		navigationBar.scrollEdgeAppearance?.titleTextAttributes[.foregroundColor] = uiColor
		navigationBar.compactScrollEdgeAppearance?.titleTextAttributes[.foregroundColor] = uiColor
	}

	@MainActor
	func setNavigationBarLargeTitleColor(_ navigationBar: UINavigationBar, _ uiColor: UIColor) {
		navigationBar.standardAppearance.largeTitleTextAttributes[.foregroundColor] = uiColor
		navigationBar.compactAppearance?.largeTitleTextAttributes[.foregroundColor] = uiColor
		navigationBar.scrollEdgeAppearance?.largeTitleTextAttributes[.foregroundColor] = uiColor
		navigationBar.compactScrollEdgeAppearance?.largeTitleTextAttributes[.foregroundColor] = uiColor
	}
}
#endif

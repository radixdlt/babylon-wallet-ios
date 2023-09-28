#if os(iOS)
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
	public func navigationBarTitleColor(
		_ color: Color,
		for displayMode: NavigationBarItem.TitleDisplayMode = .automatic
	) -> some View {
		self.modifier(NavigationBarTitleColorModifier(color: color, displayMode: displayMode))
	}
}

struct NavigationBarTitleColorModifier: ViewModifier {
	let color: Color
	let displayMode: NavigationBarItem.TitleDisplayMode

	func body(content: Content) -> some View {
		content.introspect(.navigationStack, on: .iOS(.v16...), scope: [.receiver, .ancestor]) { navigationController in
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

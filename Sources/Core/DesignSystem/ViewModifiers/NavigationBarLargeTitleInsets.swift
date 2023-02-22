#if os(iOS)
import Introspect
import SwiftUI

extension View {
	public func navigationBarLargeTitleInsets(_ insets: EdgeInsets) -> some View {
		self.modifier(NavigationBarLargeTitleInsetsModifier(insets: insets))
	}
}

struct NavigationBarLargeTitleInsetsModifier: ViewModifier {
	let insets: EdgeInsets

	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.layoutMargins.top = insets.top
			navigationBar.layoutMargins.left = insets.leading
			navigationBar.layoutMargins.right = insets.trailing
			navigationBar.layoutMargins.bottom = insets.bottom
		}
	}
}
#endif

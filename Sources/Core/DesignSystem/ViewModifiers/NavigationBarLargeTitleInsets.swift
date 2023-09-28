#if os(iOS)
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
	public func navigationBarLargeTitleInsets(_ insets: EdgeInsets) -> some View {
		self.modifier(NavigationBarLargeTitleInsetsModifier(insets: insets))
	}
}

struct NavigationBarLargeTitleInsetsModifier: ViewModifier {
	let insets: EdgeInsets

	func body(content: Content) -> some View {
		content.introspect(.navigationStack, on: .iOS(.v16...), scope: [.receiver, .ancestor]) { navigationController in
			let navigationBar = navigationController.navigationBar
			navigationBar.layoutMargins.top = insets.top
			navigationBar.layoutMargins.left = insets.leading
			navigationBar.layoutMargins.right = insets.trailing
			navigationBar.layoutMargins.bottom = insets.bottom
		}
	}
}
#endif

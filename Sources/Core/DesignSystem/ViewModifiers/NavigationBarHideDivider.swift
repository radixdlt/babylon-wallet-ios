#if os(iOS)
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {
	public func navigationBarHideDivider() -> some View {
		modifier(NavigationBarHideDividerModifier())
	}
}

struct NavigationBarHideDividerModifier: ViewModifier {
	func body(content: Content) -> some View {
		content.introspect(.navigationStack, on: .iOS(.v16...), scope: [.receiver, .ancestor]) { navigationController in
			let appearance = UINavigationBarAppearance()
			appearance.configureWithDefaultBackground()
			appearance.shadowColor = .clear
			appearance.backgroundColor = .white
			navigationController.navigationBar.scrollEdgeAppearance = appearance
		}
	}
}

#endif

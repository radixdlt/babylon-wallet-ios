#if os(iOS)

extension View {
	public func navigationBarHideDivider() -> some View {
		modifier(NavigationBarHideDividerModifier())
	}
}

struct NavigationBarHideDividerModifier: ViewModifier {
	func body(content: Content) -> some View {
		content.introspectNavigationController { navigationController in
			let appearance = UINavigationBarAppearance()
			appearance.configureWithDefaultBackground()
			appearance.shadowColor = .clear
			appearance.backgroundColor = .white
			navigationController.navigationBar.scrollEdgeAppearance = appearance
		}
	}
}

#endif

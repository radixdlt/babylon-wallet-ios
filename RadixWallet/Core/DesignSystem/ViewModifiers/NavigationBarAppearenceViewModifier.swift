import SwiftUI

extension View {
	func configureNavigationBarAppearence() -> some View {
		modifier(NavigationBarAppearenceViewModifier())
	}
}

// MARK: - NavigationBarAppearenceViewModifier
private struct NavigationBarAppearenceViewModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.onFirstTask { @MainActor in
				configureNavigationBarAppearence()
			}
	}

	@MainActor
	private func configureNavigationBarAppearence() {
		func setUp(appearence: UINavigationBarAppearance) {
			appearence.titleTextAttributes = [.foregroundColor: Color.app.gray1.uiColor, .font: UIFont(font: FontFamily.IBMPlexSans.semiBold, size: 16)!]
			appearence.largeTitleTextAttributes = [.foregroundColor: Color.app.gray1.uiColor]
			let image = UIImage(named: "arrow-back")
			appearence.setBackIndicatorImage(image, transitionMaskImage: image)
			appearence.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
		}

		let scrollEdgeAppearence = UINavigationBarAppearance()
		scrollEdgeAppearence.configureWithTransparentBackground()
		setUp(appearence: scrollEdgeAppearence)
		UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearence

		let standardAppearence = UINavigationBarAppearance()
		standardAppearence.configureWithOpaqueBackground()
		standardAppearence.backgroundColor = Color.app.background.uiColor
		setUp(appearence: standardAppearence)
		UINavigationBar.appearance().standardAppearance = standardAppearence
	}
}

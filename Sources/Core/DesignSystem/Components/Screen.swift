import SwiftUI

// MARK: - Screen
public struct Screen<Content>: View where Content: View {
	let content: Content
	let navigationBar: NavigationBar

	public init(
		title navigationTitle: String,
		navBarActionStyle navigationStyle: NavigationBar.Style,
		action navigationAction: @escaping () -> Void,
		@ViewBuilder makeContent: () -> Content
	) {
		navigationBar = NavigationBar(navigationTitle, style: navigationStyle, action: navigationAction)
		content = makeContent()
	}
}

public extension Screen {
	var body: some View {
		ForceFullScreen {
			VStack {
				navigationBar
				ForceFullScreen {
					content
				}
			}
		}
	}
}

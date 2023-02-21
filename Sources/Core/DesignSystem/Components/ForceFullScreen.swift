import Prelude
import SwiftUI

// MARK: - ForceFullScreen
public struct ForceFullScreen<Content>: View where Content: View {
	@Environment(\.colorScheme) var colorScheme

	// Could also be saved as function `() -> Content`, but evaluating closure
	// inside init and storing as value seems to be best choice:
	// https://github.com/pointfreeco/swift-composable-architecture/issues/1022#issuecomment-1067816722
	private let content: Content

	public init(
		@ViewBuilder content: () -> Content
	) {
		self.content = content()
	}

	public var body: some View {
		ZStack {
			background.edgesIgnoringSafeArea(.all)
			content
		}
	}
}

extension ForceFullScreen {
	private var background: some View {
		colorScheme == .dark ? Color.app.backgroundDark : .app.backgroundLight
	}
}

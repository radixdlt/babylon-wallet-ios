import SwiftUI

// MARK: - WithNavigationBar
struct WithNavigationBar<Content: View>: View {
	private let closeAction: () -> Void
	private let content: Content

	init(
		closeAction: @escaping () -> Void,
		@ViewBuilder content: () -> Content
	) {
		self.init(
			closeAction: closeAction,
			content: content()
		)
	}

	init(
		closeAction: @escaping () -> Void,
		content: Content
	) {
		self.content = content
		self.closeAction = closeAction
	}

	var body: some View {
		NavigationStack {
			content
				.presentationDragIndicator(.visible)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton(action: closeAction)
					}
				}
		}
	}
}

extension View {
	var inNavigationView: some View {
		NavigationView {
			self
		}
	}

	@MainActor
	var inNavigationStack: some View {
		NavigationStack {
			self
		}
	}

	func withNavigationBar(
		closeAction: @escaping () -> Void
	) -> some View {
		WithNavigationBar(closeAction: closeAction, content: self)
	}
}

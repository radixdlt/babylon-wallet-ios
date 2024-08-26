import SwiftUI

// MARK: - WithNavigationBar
public struct WithNavigationBar<Content: View>: View {
	private let closeAction: () -> Void
	private let content: Content

	public init(
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

	public var body: some View {
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
	public var inNavigationView: some View {
		NavigationView {
			self
		}
	}

	@MainActor
	public var inNavigationStack: some View {
		NavigationStack {
			self
		}
	}

	public func withNavigationBar(
		closeAction: @escaping () -> Void
	) -> some View {
		WithNavigationBar(closeAction: closeAction, content: self)
	}
}

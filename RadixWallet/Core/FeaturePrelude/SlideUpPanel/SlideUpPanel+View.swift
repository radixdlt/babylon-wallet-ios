
extension SlideUpPanel.State {
	var viewState: SlideUpPanel.ViewState {
		.init(
			title: title,
			explanation: explanation
		)
	}
}

// MARK: - WithNavigationBar
public struct WithNavigationBar<Content: View>: View {
	private let closeButtonLocation: ToolbarItemPlacement
	private let closeAction: () -> Void
	private let content: Content

	public init(
		_ closeButtonLocation: ToolbarItemPlacement = .primaryAction,
		closeAction: @escaping () -> Void,
		@ViewBuilder content: () -> Content
	) {
		self.init(
			closeButtonLocation,
			closeAction: closeAction,
			content: content()
		)
	}

	init(
		_ closeButtonLocation: ToolbarItemPlacement = .primaryAction,
		closeAction: @escaping () -> Void,
		content: Content
	) {
		self.closeButtonLocation = closeButtonLocation
		self.content = content
		self.closeAction = closeAction
	}

	public var body: some View {
		NavigationStack {
			content
				.presentationDragIndicator(.visible)
				.toolbar {
					ToolbarItem(placement: closeButtonLocation) {
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
		_ closeButtonLocation: ToolbarItemPlacement = .primaryAction,
		closeAction: @escaping () -> Void
	) -> some View {
		WithNavigationBar(closeButtonLocation, closeAction: closeAction, content: self)
	}
}

// MARK: - SlideUpPanel.View
extension SlideUpPanel {
	public struct ViewState: Equatable {
		let title: String
		let explanation: String
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SlideUpPanel>

		public init(store: StoreOf<SlideUpPanel>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					CloseButtonBar {
						viewStore.send(.closeButtonTapped)
					}

					ScrollView {
						VStack(spacing: .large3) {
							Text(viewStore.title)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)

							Text(viewStore.explanation)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.leading)

							Spacer()
						}
						.padding(.medium3)
					}
				}
				.presentationDetents([.medium])
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
				.onWillDisappear {
					viewStore.send(.willDisappear)
				}
			}
		}
	}
}

#if DEBUG

// MARK: - SlideUpPanel_Preview
struct SlideUpPanel_Preview: PreviewProvider {
	static var previews: some View {
		SlideUpPanel.View(
			store: .init(
				initialState: .previewValue,
				reducer: SlideUpPanel.init
			)
		)
	}
}

extension SlideUpPanel.State {
	public static let previewValue = Self(
		title: "A title",
		explanation: "Explanation text that can span across multiple lines and can probably be very long"
	)
}
#endif

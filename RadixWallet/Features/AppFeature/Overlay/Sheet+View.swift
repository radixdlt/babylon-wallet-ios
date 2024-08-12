import Foundation

extension Sheet {
	public struct View: SwiftUI.View {
		private let store: StoreOf<Sheet>

		public init(store: StoreOf<Sheet>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .zero) {
					HStack(spacing: .zero) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}

						Spacer()
					}
					.padding(.horizontal, .medium3)

					Group {
						Text(viewStore.title)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)
							.padding(.bottom, .large2)

						if let attributed = try? AttributedString(markdown: viewStore.text) {
							Text(attributed)
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)
								.multilineTextAlignment(.leading)
								.flushedLeft
								.environment(\.openURL, openURL)
						}
					}
					.padding(.horizontal, .large2)

					Spacer()
				}
				.padding(.top, .medium3)
				.animation(.default, value: viewStore.state)
			}
		}

		private var openURL: OpenURLAction {
			OpenURLAction { url in
				if let infoLink = OverlayWindowClient.InfoLink(url: url) {
					store.send(.view(.infoLinkTapped(infoLink)))
					return .handled
				} else {
					return .systemAction
				}
			}
		}
	}
}

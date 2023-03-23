import FeaturePrelude

extension SlideUpPanel.State {
	var viewState: SlideUpPanel.ViewState {
		.init(
			title: title,
			explanation: explanation
		)
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
					topBar(with: viewStore)

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
				#if os(iOS)
				.onWillDisappear {
					viewStore.send(.willDisappear)
				}
				#endif
			}
		}

		private func topBar(with viewStore: ViewStoreOf<SlideUpPanel>) -> some SwiftUI.View {
			HStack {
				CloseButton { viewStore.send(.closeButtonTapped) }
				Spacer()
			}
			.padding(.small2)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SlideUpPanel_Preview
struct SlideUpPanel_Preview: PreviewProvider {
	static var previews: some View {
		SlideUpPanel.View(
			store: .init(
				initialState: .previewValue,
				reducer: SlideUpPanel()
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

import Foundation

extension UnknownDappComponents {
	public struct View: SwiftUI.View {
		public let store: StoreOf<UnknownDappComponents>

		public init(store: StoreOf<UnknownDappComponents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			store.withState { state in
				VStack(spacing: .large1) {
					HStack {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
						.padding(.trailing, .medium3)

						Spacer()
						Text(L10n.TransactionReview.unknownComponents(state.components.count))
							.textStyle(.body1Header)
							.foregroundColor(.app.gray1)
						Spacer()
					}

					List(state.components) { componentAddress in
						row(componentAddress)
					}
					.listStyle(.plain)
				}
			}
		}

		@ViewBuilder
		private func row(_ componentAddress: ComponentAddress) -> some SwiftUI.View {
			HStack(spacing: .medium3) {
				DappThumbnail(.unknown)
				VStack(alignment: .leading, spacing: .zero) {
					Text(L10n.Common.component)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)

					AddressView(.address(.component(componentAddress)))
						.textStyle(.body2Regular)
						.foregroundColor(.app.gray2)
				}
				Spacer()
			}
			.alignmentGuide(.listRowSeparatorLeading) { _ in
				.medium3
			}
			.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
				viewDimensions[.listRowSeparatorTrailing] - .medium3
			}
		}
	}
}

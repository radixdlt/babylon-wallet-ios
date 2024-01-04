extension UnknownDappComponents {
	public struct View: SwiftUI.View {
		public let store: StoreOf<UnknownDappComponents>

		public init(store: StoreOf<UnknownDappComponents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			store.withState { state in
				ScrollView {
					ForEach(state.components) { componentAddress in
						row(componentAddress)
					}
				}
				.navigationTitle(L10n.TransactionReview.unknownComponents(state.components.count))
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					CloseButton { store.send(.view(.closeButtonTapped)) }
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
			.padding(.medium3)
			.withSeparator
		}
	}
}

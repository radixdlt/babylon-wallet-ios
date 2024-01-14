extension UnknownDappComponents {
	public struct View: SwiftUI.View {
		public let store: StoreOf<UnknownDappComponents>

		public init(store: StoreOf<UnknownDappComponents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			store.withState { state in
				ScrollView {
					ForEach(state.addresses, id: \.address) { address in
						row(address)
					}
				}
				.navigationTitle(L10n.TransactionReview.unknownComponents(state.addresses.count))
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					CloseButton { store.send(.view(.closeButtonTapped)) }
				}
			}
		}

		@ViewBuilder
		private func row(_ address: LedgerIdentifiable.Address) -> some SwiftUI.View {
			HStack(spacing: .medium3) {
				DappThumbnail(.unknown)
				VStack(alignment: .leading, spacing: .zero) {
					Text(L10n.Common.component)
						.textStyle(.body1Header)
						.foregroundColor(.app.gray1)

					AddressView(.address(address))
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

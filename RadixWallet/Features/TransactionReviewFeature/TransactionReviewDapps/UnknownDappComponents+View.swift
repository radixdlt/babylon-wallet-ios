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
						row(address, heading: state.rowHeading)
					}
				}
				.radixToolbar(title: state.title, alwaysVisible: false)
			}
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					CloseButton { store.send(.view(.closeButtonTapped)) }
				}
			}
		}

		@ViewBuilder
		private func row(_ address: LedgerIdentifiable.Address, heading: String) -> some SwiftUI.View {
			HStack(spacing: .medium3) {
				Thumbnail(.dapp, url: nil)

				VStack(alignment: .leading, spacing: .zero) {
					Text(heading)
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

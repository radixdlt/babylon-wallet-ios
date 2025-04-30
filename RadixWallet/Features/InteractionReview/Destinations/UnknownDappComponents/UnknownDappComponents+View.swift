extension InteractionReview.UnknownDappComponents {
	struct View: SwiftUI.View {
		let store: StoreOf<InteractionReview.UnknownDappComponents>

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					ForEach(store.addresses, id: \.address) { address in
						row(address, heading: store.rowHeading)
					}
				}
				.radixToolbar(title: store.title, alwaysVisible: false)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							store.send(.view(.closeButtonTapped))
						}
					}
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
						.foregroundColor(.primaryText)

					AddressView(.address(address))
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)
				}
				Spacer()
			}
			.padding(.medium3)
			.withSeparator
		}
	}
}

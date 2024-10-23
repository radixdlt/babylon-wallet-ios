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

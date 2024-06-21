extension DappInteractionVerifyDappOrigin {
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionVerifyDappOrigin>

		var body: some SwiftUI.View {
			VStack(spacing: .medium1) {
				CloseButton {
					store.send(.view(.cancel))
				}
				.flushedLeft

				VStack(spacing: .medium3) {
					Thumbnail(.dapp, url: store.dAppMetadata.thumbnail, size: .medium)

					Text("Have you come from a genuine website?")
						.foregroundColor(.app.gray1)
						.lineSpacing(0)
						.textStyle(.sheetTitle)

					Text("Before you connect to **\(store.dAppMetadata.name)**, you should be confident the site is safe.")
						.foregroundColor(.app.gray1)
						.textStyle(.body1Regular)
				}
				.multilineTextAlignment(.center)
				.padding(.bottom, .large1)

				VStack(alignment: .leading, spacing: .small3) {
					HStack(alignment: .top) {
						Text("•")
						Text("Check the website address to see if it matches what you are expecting")
					}
					HStack(alignment: .top) {
						Text("•")
						Text("If you came from a social media ad, make sure it's legitimate")
					}
				}
				.textStyle(.body1Regular)
				.padding()
				.background(.app.gray4)
				.roundedCorners(radius: 5.0)

				Spacer()
			}
			.padding(.horizontal, .medium1)
			.padding(.vertical, .medium1)
			.background(.app.background)
			.footer {
				Button(L10n.DAppRequest.Login.continue) {
					store.send(.view(.continueTapped))
				}
				.buttonStyle(.primaryRectangular)
			}
		}
	}
}

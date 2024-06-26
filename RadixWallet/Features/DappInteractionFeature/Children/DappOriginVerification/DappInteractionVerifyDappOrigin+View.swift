extension DappInteractionVerifyDappOrigin {
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionVerifyDappOrigin>

		var body: some SwiftUI.View {
			NavigationStack {
				VStack(spacing: .large2) {
					headerView()
					infoPointsView()

					Spacer()
				}
				.padding(.medium1)
				.background(.app.background)
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							store.send(.view(.cancel))
						}
					}
				}
				.footer {
					Button(L10n.DAppRequest.Login.continue) {
						store.send(.view(.continueTapped))
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}

		private func headerView() -> some SwiftUI.View {
			VStack(spacing: .zero) {
				Thumbnail(.dapp, url: store.dAppMetadata.thumbnail, size: .medium)
					.padding(.bottom, .small1)

				Text("Have you come from a genuine website?")
					.foregroundColor(.app.gray1)
					.kerning(-0.5)
					.textStyle(.sheetTitle)
					.padding(.bottom, .large2)

				Text("Before you connect to **\(store.dAppMetadata.name)**, you might want to check:")
					.foregroundColor(.app.gray1)
					.textStyle(.body1Link)
			}
			.multilineTextAlignment(.center)
		}

		private func infoPointsView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small1) {
				infoPointView(1, info: "Does the website address match what you’re expecting?")
				Divider()
				infoPointView(2, info: "If you came from a social media ad, is the website legitimate?")
			}
			.padding()
			.background(.app.gray5)
			.roundedCorners(radius: 10)
		}

		private func infoPointView(_ index: Int, info: String) -> some SwiftUI.View {
			HStack(spacing: .medium3) {
				Text("\(index)")
					.textStyle(.body1HighImportance)
					.foregroundColor(.app.gray1)
					.frame(.smallest)
					.background(.clear)
					.clipShape(Circle())
					.overlay(
						Circle()
							.stroke(.app.gray1, lineWidth: 1)
					)

				Text(info)
					.lineSpacing(-4)
					.foregroundStyle(.app.gray1)
					.textStyle(.body1Regular)
			}
		}
	}
}

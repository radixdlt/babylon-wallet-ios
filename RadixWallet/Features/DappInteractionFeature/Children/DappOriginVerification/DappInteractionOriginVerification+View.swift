extension DappInteractionOriginVerification {
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionOriginVerification>

		var body: some SwiftUI.View {
			NavigationStack {
				VStack(spacing: .large2) {
					headerView()
					infoPointsView()

					Spacer()
				}
				.padding(.medium1)
				.background(.primaryBackground)
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

				Text(L10n.MobileConnect.linkTitle)
					.foregroundColor(.primaryText)
					.kerning(-0.5)
					.textStyle(.sheetTitle)
					.padding(.bottom, .large2)

				Text(markdown: L10n.MobileConnect.linkSubtitle(store.dAppMetadata.name), emphasizedColor: .primaryText, emphasizedFont: .app.body1Header)
					.foregroundColor(.primaryText)
					.textStyle(.body1Link)
			}
			.multilineTextAlignment(.center)
		}

		private func infoPointsView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .small1) {
				infoPointView(1, info: L10n.MobileConnect.linkBody1)
				Divider()
				infoPointView(2, info: L10n.MobileConnect.linkBody2)
			}
			.padding()
			.background(.tertiaryBackground)
			.roundedCorners(radius: 10)
		}

		private func infoPointView(_ index: Int, info: String) -> some SwiftUI.View {
			HStack(spacing: .medium3) {
				Text("\(index)")
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)
					.frame(.smallest)
					.background(.clear)
					.clipShape(Circle())
					.overlay(
						Circle()
							.stroke(.primaryText, lineWidth: 1)
					)

				Text(info)
					.lineSpacing(-4)
					.foregroundStyle(.primaryText)
					.textStyle(.body1Regular)
			}
		}
	}
}

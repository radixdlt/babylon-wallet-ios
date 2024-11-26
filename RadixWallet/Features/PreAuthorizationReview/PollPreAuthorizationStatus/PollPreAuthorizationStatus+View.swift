// MARK: - PollPreAuthorizationStatus.View
extension PollPreAuthorizationStatus {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PollPreAuthorizationStatus>

		@ScaledMetric private var height: CGFloat = 485

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				WithNavigationBar {
					store.send(.view(.closeButtonTapped))
				} content: {
					VStack(spacing: .zero) {
						Spacer()
						VStack(spacing: .medium1) {
							topAsset(viewStore.status)

							Text(viewStore.title)
								.textStyle(.sheetTitle)
								.foregroundStyle(.app.gray1)

							VStack(spacing: .small1) {
								Text(viewStore.subtitle)
									.textStyle(.body1Regular)
									.foregroundStyle(.app.gray1)

								if viewStore.showAddressView {
									AddressView(.preAuthorization(viewStore.subintentHash))
										.foregroundColor(.app.blue1)
										.textStyle(.body1Header)
								}
							}
						}
						.padding(.horizontal, .large2)

						Spacer()

						switch viewStore.status {
						case .unknown:
							unknownBottom(text: viewStore.expirationMessage)
						case .expired:
							expiredBottom(showBrowserMessage: viewStore.isDeepLink)
						}
					}
					.multilineTextAlignment(.center)
				}
				.onFirstTask { @MainActor in
					store.send(.view(.onFirstTask))
				}
				.presentationDragIndicator(.visible)
				.presentationDetents([.height(height), .large])
				.presentationBackground(.blur)
			}
		}

		@ViewBuilder
		private func topAsset(_ status: Status) -> some SwiftUI.View {
			switch status {
			case .unknown:
				InteractionReview.InteractionInProgressView()
			case .expired:
				Image(.errorLarge)
			}
		}

		private func unknownBottom(text: String) -> some SwiftUI.View {
			Text(markdown: text, emphasizedColor: .app.account4pink, emphasizedFont: .app.button)
				.textStyle(.body1Regular)
				.foregroundStyle(.app.account4pink)
				.padding(.medium1)
				.frame(maxWidth: .infinity)
				.background(.app.gray5)
		}

		@ViewBuilder
		private func expiredBottom(showBrowserMessage: Bool) -> some SwiftUI.View {
			if showBrowserMessage {
				Text(L10n.PreAuthorizationReview.ExpiredStatus.retryInBrowser)
					.textStyle(.body1Regular)
					.foregroundStyle(.app.gray1)
					.padding(.medium1)
					.frame(maxWidth: .infinity)
					.background(.app.gray5)
			}
		}
	}
}

private extension PollPreAuthorizationStatus.State {
	var title: String {
		switch status {
		case .unknown:
			L10n.PreAuthorizationReview.UnknownStatus.title
		case .expired:
			L10n.PreAuthorizationReview.ExpiredStatus.title
		}
	}

	var subtitle: String {
		switch status {
		case .unknown:
			L10n.PreAuthorizationReview.UnknownStatus.subtitle(dAppMetadata.name)
		case .expired:
			L10n.PreAuthorizationReview.ExpiredStatus.subtitle
		}
	}

	var showAddressView: Bool {
		status == .unknown
	}

	var expirationMessage: String {
		if secondsToExpiration > 0 {
			let time = PreAuthorizationReview.TimeFormatter.format(seconds: secondsToExpiration)
			return L10n.PreAuthorizationReview.UnknownStatus.expiration(dAppMetadata.name, time)
		} else {
			return L10n.PreAuthorizationReview.UnknownStatus.lastCheck
		}
	}
}

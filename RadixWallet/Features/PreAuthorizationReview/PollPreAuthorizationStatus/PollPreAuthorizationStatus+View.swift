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
								.foregroundStyle(.primaryText)

							VStack(spacing: .small1) {
								Text(viewStore.subtitle)
									.textStyle(.body1Regular)
									.foregroundStyle(.primaryText)

								if let ledgerIdentifiable = viewStore.ledgerIdentifiable {
									AddressView(ledgerIdentifiable)
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
						case .success:
							successBottom(showBrowserMessage: viewStore.isDeepLink)
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
				.animation(.default, value: viewStore.status)
			}
		}

		@ViewBuilder
		private func topAsset(_ status: Status) -> some SwiftUI.View {
			switch status {
			case .unknown:
				InteractionReview.InteractionInProgressView()
			case .expired:
				Image(.errorLarge)
			case .success:
				Image(.successCheckmark)
			}
		}

		private func unknownBottom(text: String) -> some SwiftUI.View {
			Text(markdown: text, emphasizedColor: .app.account4pink, emphasizedFont: .app.button)
				.textStyle(.body1Regular)
				.foregroundStyle(.app.account4pink)
				.padding(.medium1)
				.frame(maxWidth: .infinity)
				.background(.secondaryBackground)
		}

		@ViewBuilder
		private func expiredBottom(showBrowserMessage: Bool) -> some SwiftUI.View {
			if showBrowserMessage {
				Text(L10n.PreAuthorizationReview.ExpiredStatus.retryInBrowser)
					.textStyle(.body1Regular)
					.foregroundStyle(.primaryText)
					.padding(.medium1)
					.frame(maxWidth: .infinity)
					.background(.secondaryBackground)
			}
		}

		@ViewBuilder
		private func successBottom(showBrowserMessage: Bool) -> some SwiftUI.View {
			if showBrowserMessage {
				Text(L10n.MobileConnect.interactionSuccess)
					.textStyle(.body1Regular)
					.foregroundStyle(.primaryText)
					.padding(.medium1)
					.frame(maxWidth: .infinity)
					.background(.secondaryBackground)
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
		case .success:
			L10n.DAppRequest.Completion.title
		}
	}

	var subtitle: String {
		switch status {
		case .unknown:
			L10n.PreAuthorizationReview.UnknownStatus.subtitle(dAppMetadata.name)
		case .expired:
			L10n.PreAuthorizationReview.ExpiredStatus.subtitle
		case .success:
			L10n.DAppRequest.Completion.subtitlePreAuthorization
		}
	}

	var ledgerIdentifiable: LedgerIdentifiable? {
		switch status {
		case .unknown:
			.preAuthorization(subintentHash)
		case .expired:
			nil
		case let .success(intentHash):
			.transaction(intentHash)
		}
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

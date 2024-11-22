// MARK: - PreAuthorizationReview.PollingStatus.View
extension PreAuthorizationReview.PollingStatus {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview.PollingStatus>

		@ScaledMetric private var height: CGFloat = 430

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				WithNavigationBar {
					store.send(.view(.closeButtonTapped))
				} content: {
					VStack(spacing: .zero) {
						VStack(spacing: .medium1) {
							topAsset(viewStore.status)

							Text(viewStore.title)
								.textStyle(.sheetTitle)
								.foregroundStyle(.app.gray1)

							VStack(spacing: .small1) {
								Text(viewStore.subtitle)
									.textStyle(.body1Regular)
									.foregroundStyle(.app.gray1)

								if viewStore.showId {
									HStack(spacing: .small3) {
										Text("Pre-Authorization ID")
											.foregroundColor(.app.gray1)
										AddressView(.preAuthorization(viewStore.subintentHash))
											.foregroundColor(.app.blue1)
									}
									.textStyle(.body1Header)
								}
							}

							Spacer()
						}
						.padding(.horizontal, .large2)

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
			Text(markdown: text, emphasizedColor: .app.account4pink, emphasizedFont: .app.body2Link)
				.textStyle(.body1Regular)
				.foregroundStyle(.app.account4pink)
				.padding(.medium1)
				.frame(maxWidth: .infinity)
				.background(.app.gray5)
		}

		@ViewBuilder
		private func expiredBottom(showBrowserMessage: Bool) -> some SwiftUI.View {
			if showBrowserMessage {
				Text("Switch back to your browser to try again")
					.textStyle(.body1Regular)
					.foregroundStyle(.app.gray1)
					.padding(.medium1)
					.frame(maxWidth: .infinity)
					.background(.app.gray5)
			}
		}
	}
}

private extension PreAuthorizationReview.PollingStatus.State {
	var title: String {
		switch status {
		case .unknown:
			"Pre-Authorization Sent"
		case .expired:
			"Pre-Authorization Timed Out"
		}
	}

	var subtitle: String {
		switch status {
		case .unknown:
			"Your pre-authorization has been sent to \(dAppMetadata.name)"
		case .expired:
			"Your pre-authorization has expired and can no longer be used."
		}
	}

	var showId: Bool {
		status == .unknown
	}

	var expirationMessage: String {
		if secondsToExpiration > 1 {
			let time = PreAuthorizationReview.TimeFormatter.format(seconds: secondsToExpiration)
			return "\(dAppMetadata.name) has \(time) to use this pre-authorization"
		} else {
			return "Checking last time.."
		}
	}
}

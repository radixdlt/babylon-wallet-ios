// MARK: - PreAuthorizationReview.PollStatus.View
extension PreAuthorizationReview.PollStatus {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PreAuthorizationReview.PollStatus>

		@ScaledMetric private var height: CGFloat = 360

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				WithNavigationBar {
					store.send(.view(.closeButtonTapped))
				} content: {
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
								AddressView(.preAuthorization(viewStore.subintentHash))
							}
						}
					}
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
	}
}

private extension PreAuthorizationReview.PollStatus.State {
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
			"Your pre-authorization has been sent to \(dAppName)"
		case .expired:
			"Your pre-authorization has expired and can no longer be used."
		}
	}

	var showId: Bool {
		status == .unknown
	}

	private var dAppName: String {
		dAppMetadata?.name?.rawValue ?? "dApp"
	}
}

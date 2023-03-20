import FeaturePrelude

// MARK: - TransactionReviewDappsUsed.View
extension TransactionReviewNetworkFee {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewNetworkFee>

		public init(store: StoreOf<TransactionReviewNetworkFee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in

				VStack(alignment: .leading, spacing: .small2) {
					HStack {
						Text(L10n.TransactionReview.NetworkFee.heading)
							.sectionHeading

						Button {
							viewStore.send(.infoTapped)
						} label: {
							Image(asset: AssetResource.info)
								.renderingMode(.template)
								.foregroundColor(.app.gray3)
						}

						Spacer(minLength: 0)

						Text("XRD \(viewStore.fee.format(maxPlaces: 1))") // TODO:  Revisit
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)
					}

					if viewStore.isCongested {
						Text(L10n.TransactionReview.NetworkFee.congestedText)
							.textStyle(.body1Regular)
							.foregroundColor(.app.alert)
					}

					Button(L10n.TransactionReview.NetworkFee.customizeButtonTitle) {
						viewStore.send(.customizeTapped)
					}
					.textStyle(.body1StandaloneLink)
					.foregroundColor(.app.blue2)
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}
	}
}

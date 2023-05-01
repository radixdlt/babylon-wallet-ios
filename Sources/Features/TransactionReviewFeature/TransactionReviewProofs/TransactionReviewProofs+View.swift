import FeaturePrelude

// MARK: - TransactionReviewProofs.View
extension TransactionReviewProofs {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewProofs>

		public init(store: StoreOf<TransactionReviewProofs>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: 0) {
					HStack {
						Text(L10n.TransactionReview.presentingHeading)
							.sectionHeading
							.textCase(.uppercase)

						TransactionReviewInfoButton {
							viewStore.send(.infoTapped)
						}

						Spacer(minLength: 0)
					}
					.padding(.bottom, .medium2)

					ForEach(viewStore.proofs) { proof in
						VStack(spacing: 0) {
							let metadata = proof.metadata
							DappView(thumbnail: metadata?.thumbnail, name: metadata?.name ?? L10n.TransactionReview.unknown) {
								viewStore.send(.proofTapped(id: proof.id))
							}
							.padding(.bottom, .medium3)

							if proof.id != viewStore.proofs.last?.id {
								Separator()
									.padding(.bottom, .medium3)
							}
						}
					}
				}
			}
			.padding(.horizontal, .medium3)
			.padding(.bottom, .medium1)
		}

		struct DappView: SwiftUI.View {
			let thumbnail: URL?
			let name: String
			let action: () -> Void

			var body: some SwiftUI.View {
				Button(action: action) {
					HStack(spacing: 0) {
						DappThumbnail(.known(thumbnail), size: .smallest)
							.padding(.trailing, .small1)

						Text(name)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray1)

						Spacer(minLength: 0)
					}
				}
			}
		}
	}
}

import FeaturePrelude

// MARK: - TransactionReviewPresenting.View
extension TransactionReviewPresenting {
	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewPresenting>

		public init(store: StoreOf<TransactionReviewPresenting>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(alignment: .leading, spacing: 0) {
					HStack {
						Text(L10n.TransactionReview.presentingHeading)
							.sectionHeading

						TransactionReviewInfoButton {
							viewStore.send(.infoTapped)
						}

						Spacer(minLength: 0)
					}
					.padding(.bottom, .medium2)

					ForEach(viewStore.dApps) { dApp in
						VStack(spacing: 0) {
							let metadata = dApp.metadata
							DappView(thumbnail: metadata?.thumbnail, name: metadata?.name ?? "Unknown name") { // TODO: 
								viewStore.send(.dAppTapped(id: dApp.id))
							}
							.padding(.bottom, .medium3)

							if dApp.id != viewStore.dApps.last?.id {
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
						DappPlaceholder(size: .smallest)
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

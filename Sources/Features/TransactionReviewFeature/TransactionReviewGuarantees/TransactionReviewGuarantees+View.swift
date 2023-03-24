import FeaturePrelude

// MARK: - TransactionReviewPresenting.View
extension TransactionReviewGuarantees {
	public struct ViewState: Equatable {
		let guarantees: [View.GuaranteeView.ViewState]
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView(showsIndicators: false) {
						VStack(spacing: 0) {
							Text("Customize Guarantees")
								.textStyle(.sheetTitle)
								.foregroundColor(.app.gray1)
								.padding(.top, .small3)
								.padding(.bottom, .medium3)

							Button("How do guarantees work", asset: AssetResource.info) {
								viewStore.send(.infoTapped)
							}
							.textStyle(.body1Header)
							.foregroundColor(.app.blue2)
							.padding(.bottom, .medium1)

							Text("Protect yourself by setting guaranteed minimums for estimated deposits")
								.textStyle(.body1Regular)
								.foregroundColor(.app.gray1)
								.padding(.bottom, .medium1)
						}
					}
					.padding(.horizontal, .medium3)
					.padding(.bottom, .medium1)
					.toolbar {
						ToolbarItem(placement: .cancellationAction) {
							CloseButton {
								viewStore.send(.closeTapped)
							}
						}
					}
				}
			}
		}

		struct GuaranteeView: SwiftUI.View {
			struct ViewState: Equatable {
				let token: TransactionReviewTokenView.ViewState
				let minimum: Double
			}

			let viewState: ViewState
			let increaseAction: () -> Void
			let decreaseAction: () -> Void

			public var body: some SwiftUI.View {
				Card {
					VStack(spacing: 0) {
						TransactionReviewTokenView(viewState: viewState.token)

						Rectangle()
							.stroke(.pink)
							.padding(.medium3)
							.overlay {
								Button(action: increaseAction) {
									Image(systemName: "minus.circle")
								}
								Text(viewState.minimum.formatted(.number))
								Button(action: increaseAction) {
									Image(systemName: "plus.circle")
								}
							}
					}
				}
			}
		}
	}
}

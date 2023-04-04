import FeaturePrelude

extension TransactionReviewGuarantees.State {
	var viewState: TransactionReviewGuarantees.ViewState {
		.init(isValid: isValid)
	}
}

// MARK: - TransactionReviewGuarantees.View
extension TransactionReviewGuarantees {
	public struct ViewState: Equatable {
		let isValid: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<TransactionReviewGuarantees>

		public init(store: StoreOf<TransactionReviewGuarantees>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				ScrollView(showsIndicators: false) {
					VStack(spacing: 0) {
						Text(L10n.TransactionReview.Guarantees.title)
							.textStyle(.sheetTitle)
							.foregroundColor(.app.gray1)
							.multilineTextAlignment(.center)
							.padding(.vertical, .medium3)

						Button(L10n.TransactionReview.Guarantees.infoButtonText, asset: AssetResource.info) {
							ViewStore(store).send(.view(.infoTapped))
						}
						.textStyle(.body1Header)
						.foregroundColor(.app.blue2)
						.padding(.horizontal, .large2)
						.padding(.bottom, .medium1)

						Text(L10n.TransactionReview.Guarantees.headerText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.foregroundColor(.app.gray1)
							.padding(.horizontal, .large2)
							.padding(.bottom, .medium1)
					}
					.frame(maxWidth: .infinity)

					VStack(spacing: .medium2) {
						ForEachStore(
							store.scope(
								state: \.guarantees,
								action: { .child(.guarantee(id: $0, action: $1)) }
							),
							content: { TransactionReviewGuarantee.View(store: $0) }
						)
					}
					.padding(.medium1)
					.background(.app.gray5)
				}
				.footer {
					WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
						Button(L10n.TransactionReview.Guarantees.applyButtonText) {
							viewStore.send(.applyTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.isValid ? .enabled : .disabled)
					}
				}
				.sheet(store: store.scope(state: \.$info, action: { .child(.info($0)) })) {
					SlideUpPanel.View(store: $0)
						.presentationDetents([.medium])
						.presentationDragIndicator(.visible)
					#if os(iOS)
						.presentationBackground(.blur)
					#endif
				}
				.toolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							ViewStore(store).send(.view(.closeTapped))
						}
					}
				}
			}
		}
	}
}

extension TransactionReviewGuarantee.State {
	var viewState: TransactionReviewGuarantee.ViewState {
		.init(id: transfer.id, account: account, token: .init(transfer: transfer))
	}
}

extension TransactionReviewTokenView.ViewState {
	init(transfer: TransactionReview.Transfer) {
		self.init(name: transfer.metadata.name,
		          isXRD: transfer.isXRD,
		          thumbnail: transfer.metadata.thumbnail,
		          amount: transfer.amount,
		          guaranteedAmount: transfer.guarantee?.amount,
		          fiatAmount: transfer.metadata.fiatAmount)
	}
}

extension TransactionReviewGuarantee {
	public struct ViewState: Identifiable, Equatable {
		public let id: TransactionReview.Transfer.ID
		let account: TransactionReview.Account
		let token: TransactionReviewTokenView.ViewState
	}

	public struct View: SwiftUI.View {
		public let store: StoreOf<TransactionReviewGuarantee>

		public init(store: StoreOf<TransactionReviewGuarantee>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Card(verticalSpacing: 0) {
					AccountLabel(account: viewStore.account) {
						viewStore.send(.copyAddressTapped)
					}

					TransactionReviewTokenView(viewState: viewStore.token)

					Separator()

					HStack(spacing: .medium3) {
						Text(L10n.TransactionReview.Guarantees.setText)
							.lineLimit(2)
							.textStyle(.body2Header)
							.foregroundColor(.app.gray1)

						Spacer(minLength: 0)

						let stepperStore = store.scope(state: \.percentageStepper) { .child(.percentageStepper($0)) }
						MinimumPercentageStepper.View(store: stepperStore)
					}
					.padding(.medium3)
				}
			}
		}
	}
}

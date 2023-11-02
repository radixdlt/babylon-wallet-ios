import ComposableArchitecture
import SwiftUI
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

						//	FIXME: Uncomment and implement
						//	Button(L10n.TransactionReview.Guarantees.howDoGuaranteesWork) {
						//		store.send(.view(.infoTapped))
						//	}
						//	.buttonStyle(.info)
						//	.padding(.horizontal, .large2)
						//	.padding(.bottom, .medium1)

						Text(L10n.TransactionReview.Guarantees.subtitle)
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
						.presentationBackground(.blur)
				}
				.safeToolbar {
					ToolbarItem(placement: .cancellationAction) {
						CloseButton {
							store.send(.view(.closeTapped))
						}
					}
				}
			}
		}
	}
}

extension TransactionReviewGuarantee.State {
	var viewState: TransactionReviewGuarantee.ViewState {
		.init(
			id: id,
			account: account,
			token: .init(resource: resource, details: details)
		)
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
			WithViewStore(store, observe: \.viewState) { viewStore in
				Card {
					VStack(spacing: 0) {
						SmallAccountCard(account: viewStore.account)

						TransactionReviewTokenView(viewState: viewStore.token)

						Separator()

						let stepperStore = store.scope(state: \.percentageStepper) { .child(.percentageStepper($0)) }
						MinimumPercentageStepper.View(
							store: stepperStore,
							title: L10n.TransactionReview.Guarantees.setGuaranteedMinimum
						)
						.padding(.medium3)
					}
				}
			}
		}
	}
}

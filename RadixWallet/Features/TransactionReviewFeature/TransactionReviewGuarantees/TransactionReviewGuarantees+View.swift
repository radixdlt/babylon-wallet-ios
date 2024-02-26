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
						ForEachStore(store.scope(state: \.guarantees, action: \.child.guarantee)) {
							TransactionReviewGuarantee.View(store: $0)
						}
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
				.sheet(store: store.scope(state: \.$info, action: \.child.info)) {
					SlideUpPanel.View(store: $0)
						.presentationDetents([.medium])
						.presentationDragIndicator(.visible)
						.presentationBackground(.blur)
				}
				.toolbar {
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
			fungible: .init(
				address: resource.resourceAddress,
				icon: thumbnail,
				title: resource.metadata.title,
				amount: .init(amount, guaranteed: guarantee.amount)
			)
		)
	}
}

extension TransactionReviewGuarantee {
	public struct ViewState: Identifiable, Equatable {
		public let id: TransactionReview.Transfer.ID
		let account: TransactionReview.Account
		let fungible: ResourceBalance.Fungible
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

						ResourceBalanceView(resource: .fungible(viewStore.fungible))
							.padding(.horizontal, .medium3)
							.padding(.vertical, .small1)

						Separator()

						MinimumPercentageStepper.View(
							store: store.scope(state: \.percentageStepper, action: \.child.percentageStepper),
							title: L10n.TransactionReview.Guarantees.setGuaranteedMinimum
						)
						.padding(.medium3)
					}
				}
			}
		}
	}
}

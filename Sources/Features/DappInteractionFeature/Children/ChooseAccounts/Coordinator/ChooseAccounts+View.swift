import CreateAccountFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
public extension ChooseAccounts {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ChooseAccounts>

		public init(store: StoreOf<ChooseAccounts>) {
			self.store = store
		}
	}
}

public extension ChooseAccounts.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				IfLetStore(
					store.scope(
						state: \.createAccountCoordinator,
						action: { .child(.createAccountCoordinator($0)) }
					),
					then: { CreateAccountCoordinator.View(store: $0) }
				)
				.zIndex(1)

				VStack(spacing: .zero) {
					NavigationBar(
						leadingItem: CloseButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					Spacer()
						.frame(height: .small2)

					ScrollView {
						VStack {
							VStack(spacing: .medium2) {
								Text(L10n.DApp.ChooseAccounts.explanation(viewStore.numberOfAccountsExplanation))
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)
							}
							.multilineTextAlignment(.center)

							ForEachStore(
								store.scope(
									state: \.availableAccounts,
									action: { .child(.account(id: $0, action: $1)) }
								),
								content: { ChooseAccounts.Row.View(store: $0) }
							)

							Button(L10n.DApp.ChooseAccounts.createNewAccount) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.primaryText())
							.padding(.medium1)
						}
						.padding(.horizontal, .medium1)

						Spacer()
							.frame(height: .large1 * 1.5)
					}

					ConfirmationFooter(
						title: L10n.DApp.ConnectionRequest.continueButtonTitle,
						isEnabled: viewStore.canProceed,
						action: { viewStore.send(.continueButtonTapped) }
					)
				}
			}
			.onAppear {
				viewStore.send(.didAppear)
			}
		}
	}
}

// MARK: - ChooseAccounts.View.ChooseAccountsViewStore
private extension ChooseAccounts.View {
	typealias ChooseAccountsViewStore = ComposableArchitecture.ViewStore<ChooseAccounts.View.ViewState, ChooseAccounts.Action.ViewAction>
}

// MARK: - ChooseAccounts.View.ViewState
extension ChooseAccounts.View {
	struct ViewState: Equatable {
		let canProceed: Bool
		let numberOfAccountsExplanation: String

		init(state: ChooseAccounts.State) {
			let quantifier = state.numberOfAccounts.quantifier
			let quantity = state.numberOfAccounts.quantity

			canProceed = {
				switch quantifier {
				case .atLeast:
					return state.selectedAccounts.count >= quantity
				case .exactly:
					return state.selectedAccounts.count == quantity
				}
			}()
			numberOfAccountsExplanation = {
				switch quantifier {
				case .exactly:
					if quantity == 1 {
						return L10n.DApp.ChooseAccounts.explanationExactlyOneAccount
					} else {
						return L10n.DApp.ChooseAccounts.explanationExactNumberOfAccounts(quantity)
					}
				case .atLeast:
					// TODO: revise this localization
					return L10n.DApp.ChooseAccounts.explanationAtLeastOneAccount
				}
			}()
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ChooseAccounts_Preview: PreviewProvider {
	static var previews: some View {
		ChooseAccounts.View(
			store: .init(
				initialState: .previewValue,
				reducer: ChooseAccounts()
			)
		)
	}
}
#endif

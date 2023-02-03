import CreateEntityFeature
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

				VStack {
					NavigationBar(
						leadingItem: CloseButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					ScrollView {
						VStack {
							VStack(spacing: .medium2) {
								Text(L10n.DApp.ChooseAccounts.explanation(viewStore.numberOfAccountsExplanation))
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								Text(L10n.DApp.ChooseAccounts.subtitle(viewStore.interaction.metadata.dAppId))
									.foregroundColor(.app.gray1)
									.textStyle(.body1Regular)
									.padding(.medium1)
							}
							.multilineTextAlignment(.center)

							ForEachStore(
								store.scope(
									state: \.accounts,
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

						Button(L10n.DApp.ConnectionRequest.continueButtonTitle) {
							viewStore.send(.continueButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.canProceed ? .enabled : .disabled)
						.padding(.medium1)
					}
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
		let oneTimeAccountAddressesRequest: P2P.FromDapp.WalletInteraction.OneTimeAccountsRequestItem
		let numberOfAccountsExplanation: String
		let interaction: P2P.FromDapp.WalletInteraction

		init(state: ChooseAccounts.State) {
			canProceed = {
				let numberOfAccounts = state.request.requestItem.numberOfAccounts
				switch numberOfAccounts.quantifier {
				case .atLeast:
					return state.selectedAccounts.count >= numberOfAccounts.quantity
				case .exactly:
					return state.selectedAccounts.count == numberOfAccounts.quantity
				}
			}()
			// FIXME: remove Force Unwrap
			oneTimeAccountAddressesRequest = state.request.requestItem
			interaction = state.request.parentRequest.interaction
			numberOfAccountsExplanation = {
				let numberOfAccounts = state.request.requestItem.numberOfAccounts
				switch numberOfAccounts.quantifier {
				case .exactly:
					let quantity = numberOfAccounts.quantity
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

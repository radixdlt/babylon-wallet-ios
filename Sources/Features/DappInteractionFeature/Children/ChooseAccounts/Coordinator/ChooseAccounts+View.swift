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
						VStack(spacing: .small1) {
							VStack(spacing: .medium2) {
								dappImage

								Text(L10n.DApp.ChooseAccounts.title)
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								subtitle(
									dappName: viewStore.dappName,
									message: subtitleText(with: viewStore)
								)
								.textStyle(.secondaryHeader)
								.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							ForEachStore(
								store.scope(
									state: \.availableAccounts,
									action: { .child(.account(id: $0, action: $1)) }
								),
								content: { ChooseAccounts.Row.View(store: $0) }
							)

							Spacer()
								.frame(height: .small3)

							Button(L10n.DApp.ChooseAccounts.createNewAccount) {
								viewStore.send(.createAccountButtonTapped)
							}
							.buttonStyle(.secondaryRectangular(
								shouldExpand: false
							))

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}

					ConfirmationFooter(
						title: L10n.DApp.LoginRequest.continueButtonTitle,
						isEnabled: viewStore.canProceed,
						action: {}
					)
				}
			}
			.onAppear {
				viewStore.send(.didAppear)
			}

			/*
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
			 */
		}
	}
}

// MARK: - ChooseAccounts.View.ChooseAccountsViewStore
private extension ChooseAccounts.View {
	typealias ChooseAccountsViewStore = ComposableArchitecture.ViewStore<ChooseAccounts.View.ViewState, ChooseAccounts.Action.ViewAction>
}

// MARK: - Private Computed Properties
private extension ChooseAccounts.View {
	var dappImage: some View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	func subtitle(dappName: String, message: String) -> some View {
		var component1 = AttributedString(message)
		component1.foregroundColor = .app.gray2

		var component2 = AttributedString(dappName)
		component2.foregroundColor = .app.gray1

		return Text(component1 + component2)
	}

	func subtitleText(with viewStore: ChooseAccountsViewStore) -> String {
//		"Choose 1 account you wish to use with "
		"Choose at least 2 accounts you wish to use with "
//		Choose any accounts you wish to use with Collabo.Fi.

		/*
		 viewStore.isKnownDapp ?
		 	L10n.DApp.LoginRequest.Subtitle.knownDapp :
		 	L10n.DApp.LoginRequest.Subtitle.newDapp
		 */
	}
}

// MARK: - ChooseAccounts.View.ViewState
extension ChooseAccounts.View {
	struct ViewState: Equatable {
		let dappName: String
		let canProceed: Bool
		let numberOfAccountsExplanation: String

		init(state: ChooseAccounts.State) {
			dappName = state.dappMetadata.name

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

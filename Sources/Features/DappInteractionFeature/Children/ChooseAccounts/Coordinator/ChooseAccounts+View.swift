import CreateEntityFeature
import FeaturePrelude

// MARK: - ChooseAccounts.View
extension ChooseAccounts {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<ChooseAccounts>
	}
}

extension ChooseAccounts.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				ScrollView {
					VStack(spacing: .small1) {
						VStack(spacing: .medium2) {
							dappImage

							Text(viewStore.title)
								.foregroundColor(.app.gray1)
								.textStyle(.sheetTitle)

							subtitle(
								with: viewStore,
								dappName: viewStore.dappName,
								message: viewStore.subtitle
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
				.safeAreaInset(edge: .bottom) {
					ConfirmationFooter(
						title: L10n.DApp.LoginRequest.continueButtonTitle,
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

// MARK: - Private Computed Properties
private extension ChooseAccounts.View {
	var dappImage: some View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	func subtitle(
		with viewStore: ChooseAccountsViewStore,
		dappName: String,
		message: String
	) -> some View {
		var component1 = AttributedString(message)
		component1.foregroundColor = .app.gray2

		var dappname = AttributedString(dappName)
		dappname.foregroundColor = .app.gray1

		var component3 = AttributedString(".")
		component3.foregroundColor = .app.gray2

		switch viewStore.accessKind {
		case .ongoing:
			return Text(component1 + dappname + component3)
		case .oneTime:
			return Text(dappname + component1)
		}
	}
}

// MARK: - ChooseAccounts.View.ViewState
extension ChooseAccounts.View {
	struct ViewState: Equatable {
		let dappName: String
		let canProceed: Bool
		let title: String
		let subtitle: String
		let accessKind: ChooseAccounts.State.AccessKind

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

			switch state.accessKind {
			case .ongoing:
				title = "Account Permission"
			case .oneTime:
				title = "Account Request"
			}

			switch state.accessKind {
			case .ongoing:
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					subtitle = "Choose any accounts you wish to use with "
				case (.atLeast, 1):
					subtitle = "Choose at least 1 account you wish to use with "
				case let (.atLeast, number):
					subtitle = "Choose at least \(number) accounts you wish to use with "
				case (.exactly, 1):
					subtitle = "Choose 1 account you wish to use with "
				case let (.exactly, number):
					subtitle = "Choose \(number) accounts you wish to use with "
				}
			case .oneTime:
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					subtitle = " is making a one-time request for any number of accounts."
				case (.atLeast, 1):
					subtitle = " is making a one-time request for at least 1 account."
				case let (.atLeast, number):
					subtitle = " is making a one-time request for at least \(number) accounts."
				case (.exactly, 1):
					subtitle = " is making a one-time request for 1 account."
				case let (.exactly, number):
					subtitle = " is making a one-time request for at least \(number) accounts."
				}
			}

			accessKind = state.accessKind
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

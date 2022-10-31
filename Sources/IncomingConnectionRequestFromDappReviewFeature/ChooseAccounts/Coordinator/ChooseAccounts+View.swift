import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - ChooseAccounts.View
public extension ChooseAccounts {
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
			send: ChooseAccounts.Action.init
		) { viewStore in
			ForceFullScreen {
				VStack {
					header(with: viewStore)
						.padding(24)

					ScrollView {
						VStack {
							Image("dapp-placeholder")

							Spacer(minLength: 40)

							VStack(spacing: 20) {
								Text(L10n.DApp.ChooseAccounts.title)
									.textStyle(.secondaryHeader)

								Text(L10n.DApp.ChooseAccounts.subtitle(viewStore.incomingConnectionRequestFromDapp.displayName))
									.foregroundColor(.app.gray2)
									.textStyle(.body1Regular)
									.padding(24)
							}
							.multilineTextAlignment(.center)

							ForEachStore(
								store.scope(
									state: \.accounts,
									action: ChooseAccounts.Action.account(id:action:)
								),
								content: ChooseAccounts.Row.View.init(store:)
							)

							Spacer(minLength: 60)

							Button(
								action: {},
								label: {
									Text(L10n.DApp.ChooseAccounts.createNewAccount)
										.foregroundColor(.app.gray1)
										.textStyle(.body1Regular)
								}
							)

							Spacer(minLength: 60)

							PrimaryButton(
								title: L10n.DApp.ConnectionRequest.continueButtonTitle,
								isEnabled: viewStore.canProceed,
								action: { viewStore.send(.continueButtonTapped) }
							)
							.disabled(!viewStore.canProceed)
						}
						.padding(.horizontal, 24)
					}
				}
			}
		}
	}
}

// MARK: - ChooseAccounts.View.ChooseAccountsViewStore
private extension ChooseAccounts.View {
	typealias ChooseAccountsViewStore = ComposableArchitecture.ViewStore<ChooseAccounts.View.ViewState, ChooseAccounts.View.ViewAction>
}

private extension ChooseAccounts.View {
	func header(with viewStore: ChooseAccountsViewStore) -> some View {
		HStack {
			BackButton {
				viewStore.send(.backButtonTapped)
			}
			Spacer()
		}
	}
}

// MARK: - ChooseAccounts.View.ViewAction
extension ChooseAccounts.View {
	enum ViewAction: Equatable {
		case continueButtonTapped
		case backButtonTapped
	}
}

extension ChooseAccounts.Action {
	init(action: ChooseAccounts.View.ViewAction) {
		switch action {
		case .continueButtonTapped:
			self = .internal(.user(.continueFromChooseAccounts))
		case .backButtonTapped:
			self = .internal(.user(.dismissChooseAccounts))
		}
	}
}

// MARK: - ChooseAccounts.View.ViewState
extension ChooseAccounts.View {
	struct ViewState: Equatable {
		var canProceed: Bool
		let incomingConnectionRequestFromDapp: IncomingConnectionRequestFromDapp

		init(state: ChooseAccounts.State) {
			canProceed = state.canProceed
			incomingConnectionRequestFromDapp = state.incomingConnectionRequestFromDapp
		}
	}
}

#if DEBUG

// MARK: - ChooseAccounts_Preview
struct ChooseAccounts_Preview: PreviewProvider {
	static var previews: some View {
		registerFonts()

		return ChooseAccounts.View(
			store: .init(
				initialState: .placeholder,
				reducer: ChooseAccounts()
			)
		)
	}
}
#endif // DEBUG

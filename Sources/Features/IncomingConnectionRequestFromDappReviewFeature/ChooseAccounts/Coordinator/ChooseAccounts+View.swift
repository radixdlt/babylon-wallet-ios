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
			send: { .view($0) }
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
								Text("Choose \(String(describing: viewStore.incomingConnectionRequestFromDapp.numberOfNeededAccounts))")
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
									action: { .child(.account(id: $0, action: $1)) }
								),
								content: ChooseAccounts.Row.View.init(store:)
							)
						}
					}
					Spacer(minLength: 16)
					VStack {
						Button(
							action: {},
							label: {
								Text(L10n.DApp.ChooseAccounts.createNewAccount)
									.foregroundColor(.app.gray1)
									.textStyle(.body1Regular)
							}
						)
						PrimaryButton(
							title: L10n.DApp.ConnectionRequest.continueButtonTitle,
							isEnabled: viewStore.canProceed,
							action: { viewStore.send(.continueButtonTapped) }
						)
					}

					Spacer(minLength: 16)
				}
				.padding(.horizontal, 24)
			}
		}
	}
}

// MARK: - IncomingConnectionRequestFromDapp.NumberOfNeededAccounts + CustomStringConvertible
extension IncomingConnectionRequestFromDapp.NumberOfNeededAccounts: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .exactly(numberOfAccounts):
			if numberOfAccounts == 1 {
				return "exactly one account."

			} else {
				return "exactly #\(numberOfAccounts) accounts."
			}
		case .atLeastOne:
			return "at least one account"
		}
	}
}

// MARK: - ChooseAccounts.View.ChooseAccountsViewStore
private extension ChooseAccounts.View {
	typealias ChooseAccountsViewStore = ComposableArchitecture.ViewStore<ChooseAccounts.View.ViewState, ChooseAccounts.Action.ViewAction>
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

import Common
import ComposableArchitecture
import DesignSystem
import SharedModels
import SwiftUI

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
				VStack {
					NavigationBar(
						leadingItem: BackButton {
							viewStore.send(.backButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					ScrollView {
						VStack {
							Image(asset: AssetResource.dappPlaceholder)

							Spacer(minLength: .large1)

							VStack(spacing: .medium2) {
								let explanation = String(describing: viewStore.oneTimeAccountAddressesRequest.numberOfAddresses)
								Text(L10n.DApp.ChooseAccounts.explanation(explanation))
									.foregroundColor(.app.gray1)
									.textStyle(.secondaryHeader)

								Text(L10n.DApp.ChooseAccounts.subtitle(viewStore.requestFromDapp.metadata.dAppId))
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
								content: ChooseAccounts.Row.View.init(store:)
							)

							Button(L10n.DApp.ChooseAccounts.createNewAccount) {
								// TODO: implement
							}
							.buttonStyle(.primaryText())
							.padding(.medium1)
						}
						.padding(.horizontal, .medium1)
					}

					Button(L10n.DApp.ConnectionRequest.continueButtonTitle) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
					.enabled(viewStore.canProceed)
					.padding(.medium1)
				}
			}
		}
	}
}

// MARK: - P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode + CustomStringConvertible
extension P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .exactly(exactly):
			let numberOfAccounts = exactly.oneOrMore
			if numberOfAccounts == 1 {
				return L10n.DApp.ChooseAccounts.explanationExactlyOneAccount
			} else {
				return L10n.DApp.ChooseAccounts.explanationExactNumberOfAccounts(Int(numberOfAccounts))
			}
		case .oneOrMore:
			return L10n.DApp.ChooseAccounts.explanationAtLeastOneAccount
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
		var canProceed: Bool
		let oneTimeAccountAddressesRequest: P2P.FromDapp.OneTimeAccountsReadRequestItem
		let requestFromDapp: P2P.FromDapp.Request

		init(state: ChooseAccounts.State) {
			canProceed = state.canProceed
			// FIXME: remove Force Unwrap
			oneTimeAccountAddressesRequest = state.request.requestItem
			requestFromDapp = state.request.parentRequest.requestFromDapp
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

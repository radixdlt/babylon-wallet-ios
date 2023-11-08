import ComposableArchitecture
import NavigationTransition
import SwiftUI

// MARK: - DappInteractionFlow.View
extension DappInteractionFlow {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionFlow>

		var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.path, action: { .child(.path($0)) })
			) {
				IfLetStore(
					store.scope(state: \.root, action: { .child(.root($0)) })
				) {
					destinations(for: $0)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									store.send(.view(.closeButtonTapped))
								}
							}
						}
				}
				// This is required to disable the animation of internal components during transition
				.transaction { $0.animation = nil }
			} destination: {
				destinations(for: $0)
					.navigationBarBackButtonHidden()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								store.send(.view(.backButtonTapped))
							}
						}
					}
			}
			.navigationTransition(.slide, interactivity: .disabled)
			.onAppear { store.send(.view(.appeared)) }
			.alert(
				store: store.scope(
					state: \.$personaNotFoundErrorAlert,
					action: { .view(.personaNotFoundErrorAlert($0)) }
				)
			)
		}

		func destinations(
			for store: StoreOf<DappInteractionFlow.Destination>
		) -> some SwiftUI.View {
			SwitchStore(store.relay()) { state in
				switch state {
				case .login:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.login,
						action: DappInteractionFlow.Destination.MainAction.login,
						then: { Login.View(store: $0) }
					)

				case .accountPermission:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.accountPermission,
						action: DappInteractionFlow.Destination.MainAction.accountPermission,
						then: { AccountPermission.View(store: $0) }
					)

				case .chooseAccounts:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.chooseAccounts,
						action: DappInteractionFlow.Destination.MainAction.chooseAccounts,
						then: { AccountPermissionChooseAccounts.View(store: $0) }
					)

				case .personaDataPermission:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.personaDataPermission,
						action: DappInteractionFlow.Destination.MainAction.personaDataPermission,
						then: { PersonaDataPermission.View(store: $0) }
					)

				case .oneTimePersonaData:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.oneTimePersonaData,
						action: DappInteractionFlow.Destination.MainAction.oneTimePersonaData,
						then: { OneTimePersonaData.View(store: $0) }
					)

				case .reviewTransaction:
					CaseLet(
						/DappInteractionFlow.Destination.MainState.reviewTransaction,
						action: DappInteractionFlow.Destination.MainAction.reviewTransaction,
						then: { TransactionReview.View(store: $0) }
					)
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - DappInteraction_Preview
struct DappInteraction_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionFlow.View(
			store: .init(
				initialState: .init(
					dappMetadata: .previewValue,
					interaction: .previewValueAllRequests()
				)!
			) {
				DappInteractionFlow()
					.dependency(\.accountsClient, .previewValueTwoAccounts())
					//  .dependency(\.authorizedDappsClient, .previewValueOnePersona())
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: true))
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: false))
			}
		)
	}
}

extension AccountsClient {
	static func previewValueTwoAccounts() -> Self {
		update(noop) {
			$0.getAccountsOnCurrentNetwork = {
				[.previewValue0, .previewValue1]
			}
		}
	}
}

extension AuthorizedDappsClient {
	static func previewValueOnePersona() -> Self {
		update(noop) {
			$0.getAuthorizedDapps = {
				var dapp = Profile.Network.AuthorizedDapp(
					networkID: .nebunet,
					dAppDefinitionAddress: try! .init(validatingAddress: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh"),
					displayName: .init(rawValue: "something")!
				)
				dapp.referencesToAuthorizedPersonas = [
					.init(
						identityAddress: Profile.Network.Persona.previewValue1.address,
						lastLogin: .now,
						sharedAccounts: try! .init(
							ids: [try! AccountAddress(validatingAddress: "account_tdx_b_1qlujhx6yh6tuctgw6nl68fr2dwg3y5k7h7mc6l04zsfsg7yeqh")],
							forRequest: .exactly(1)
						),
						sharedPersonaData: .init()
					),
				]
				return [dapp]
			}
		}
	}
}

extension PersonasClient {
	static func previewValueTwoPersonas(existing: Bool) -> Self {
		update(noop) {
			$0.getPersonas = {
				if existing {
					[.previewValue0, .previewValue1]
				} else {
					[.previewValue0]
				}
			}
		}
	}
}
#endif

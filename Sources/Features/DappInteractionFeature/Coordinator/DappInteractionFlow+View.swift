import AccountsClient
import AuthorizedDappsClient
import EngineKit
import FeaturePrelude
import PersonasClient
import TransactionReviewFeature

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
					destination(for: $0)
					#if os(iOS)
						.toolbar {
							ToolbarItem(placement: .navigationBarLeading) {
								CloseButton {
									ViewStore(store.stateless).send(.view(.closeButtonTapped))
								}
							}
						}
					#endif
				}
				// This is required to disable the animation of internal components during transition
				.transaction { $0.animation = nil }
			} destination: {
				destination(for: $0)
				#if os(iOS)
					.navigationBarBackButtonHidden()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								ViewStore(store.stateless).send(.view(.backButtonTapped))
							}
						}
					}
				#endif
			}
			#if os(iOS)
			.navigationTransition(.slide, interactivity: .disabled)
			#endif
			.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
			.alert(
				store: store.scope(
					state: \.$personaNotFoundErrorAlert,
					action: { .view(.personaNotFoundErrorAlert($0)) }
				)
			)
		}

		func destination(
			for store: StoreOf<DappInteractionFlow.Destinations>
		) -> some SwiftUI.View {
			SwitchStore(store.relay()) {
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.login,
					action: DappInteractionFlow.Destinations.MainAction.login,
					then: { Login.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.accountPermission,
					action: DappInteractionFlow.Destinations.MainAction.accountPermission,
					then: { AccountPermission.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.chooseAccounts,
					action: DappInteractionFlow.Destinations.MainAction.chooseAccounts,
					then: { AccountPermissionChooseAccounts.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.personaDataPermission,
					action: DappInteractionFlow.Destinations.MainAction.personaDataPermission,
					then: { PersonaDataPermission.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.oneTimePersonaData,
					action: DappInteractionFlow.Destinations.MainAction.oneTimePersonaData,
					then: { OneTimePersonaData.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.reviewTransaction,
					action: DappInteractionFlow.Destinations.MainAction.reviewTransaction,
					then: { TransactionReview.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DappInteraction_Preview
struct DappInteraction_Preview: PreviewProvider {
	static var previews: some View {
		DappInteractionFlow.View(
			store: .init(
				initialState: .init(
					dappMetadata: .previewValue,
					interaction: .previewValueAllRequests()
				)!,
				reducer: DappInteractionFlow()
					.dependency(\.accountsClient, .previewValueTwoAccounts())
//					.dependency(\.authorizedDappsClient, .previewValueOnePersona())
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: true))
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: false))
			)
		)
	}
}

extension AccountsClient {
	static func previewValueTwoAccounts() -> Self {
		with(noop) {
			$0.getAccountsOnCurrentNetwork = {
				NonEmpty(.previewValue0, .previewValue1)
			}
		}
	}
}

extension AuthorizedDappsClient {
	static func previewValueOnePersona() -> Self {
		with(noop) {
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
		with(noop) {
			$0.getPersonas = {
				if existing {
					return [.previewValue0, .previewValue1]
				} else {
					return [.previewValue0]
				}
			}
		}
	}
}
#endif

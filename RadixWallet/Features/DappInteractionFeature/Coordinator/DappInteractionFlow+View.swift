import ComposableArchitecture
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
					.toolbar(.visible, for: .navigationBar)
					.navigationBarBackButtonHidden()
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							BackButton {
								store.send(.view(.backButtonTapped))
							}
						}
					}
			}
			.onAppear { store.send(.view(.appeared)) }
			.alert(
				store: store.scope(
					state: \.$personaNotFoundErrorAlert,
					action: { .view(.personaNotFoundErrorAlert($0)) }
				)
			)
		}

		func destinations(
			for store: StoreOf<DappInteractionFlow.Path>
		) -> some SwiftUI.View {
			SwitchStore(store.scope(state: \.state, action: \.self)) { state in
				switch state {
				case .login:
					CaseLet(
						/DappInteractionFlow.Path.MainState.login,
						action: DappInteractionFlow.Path.Action.login,
						then: { Login.View(store: $0) }
					)

				case .accountPermission:
					CaseLet(
						/DappInteractionFlow.Path.MainState.accountPermission,
						action: DappInteractionFlow.Path.Action.accountPermission,
						then: { AccountPermission.View(store: $0) }
					)

				case .chooseAccounts:
					CaseLet(
						/DappInteractionFlow.Path.MainState.chooseAccounts,
						action: DappInteractionFlow.Path.Action.chooseAccounts,
						then: { AccountPermissionChooseAccounts.View(store: $0) }
					)

				case .personaDataPermission:
					CaseLet(
						/DappInteractionFlow.Path.MainState.personaDataPermission,
						action: DappInteractionFlow.Path.Action.personaDataPermission,
						then: { PersonaDataPermission.View(store: $0) }
					)

				case .oneTimePersonaData:
					CaseLet(
						/DappInteractionFlow.Path.MainState.oneTimePersonaData,
						action: DappInteractionFlow.Path.Action.oneTimePersonaData,
						then: { OneTimePersonaData.View(store: $0) }
					)

				case .reviewTransaction:
					CaseLet(
						/DappInteractionFlow.Path.MainState.reviewTransaction,
						action: DappInteractionFlow.Path.Action.reviewTransaction,
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
					interaction: .previewValueAllRequests(),
					p2pRoute: .wallet
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
				var dapp = AuthorizedDapp(
					networkId: .nebunet,
					dappDefinitionAddress: .sample,
					displayName: "something",
					referencesToAuthorizedPersonas: [],
					preferences: .init(deposits: .visible)
				)
				dapp.referencesToAuthorizedPersonas = [
					.sample,
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
					[.sample, .sampleOther]
				} else {
					[.sample]
				}
			}
		}
	}
}
#endif

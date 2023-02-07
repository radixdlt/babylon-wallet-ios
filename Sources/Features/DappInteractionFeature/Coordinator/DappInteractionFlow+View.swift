import FeaturePrelude
import TransactionSigningFeature

// MARK: - DappInteractionFlow.View
extension DappInteractionFlow {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionFlow>

		var body: some SwiftUI.View {
			NavigationStackStore(
				store.scope(state: \.$path, action: { .child(.path($0)) })
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
				.navigationDestination(
					store: store.scope(state: \.$path, action: { .child(.path($0)) })
				) {
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
				.navigationTransition(.slide)
				#endif
			}
			.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
			.alert(
				store.scope(
					state: \.personaNotFoundErrorAlert,
					action: { .view(.personaNotFoundErrorAlert($0)) }
				),
				dismiss: .systemDismissed
			)
		}

		func destination(
			for store: StoreOf<DappInteractionFlow.Destinations>
		) -> some SwiftUI.View {
			SwitchStore(store.relay()) {
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.login,
					action: DappInteractionFlow.Destinations.MainAction.login,
					then: { LoginRequest.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.permission,
					action: DappInteractionFlow.Destinations.MainAction.permission,
					then: { Permission.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.chooseAccounts,
					action: DappInteractionFlow.Destinations.MainAction.chooseAccounts,
					then: { ChooseAccounts.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.MainState.signAndSubmitTransaction,
					action: DappInteractionFlow.Destinations.MainAction.signAndSubmitTransaction,
					then: { TransactionSigning.View(store: $0) }
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
					interaction: .previewValueAllRequests(
						auth: .login(.init(challenge: nil))
//						auth: .usePersona(.init(identityAddress: OnNetwork.Persona.previewValue0.address.address))
//						auth: .usePersona(.init(identityAddress: "invalidaddress"))
					)
				)!,
				reducer: DappInteractionFlow()
					.dependency(\.profileClient, .previewValueTwoPersonas)
			)
		)
	}
}

import ProfileClient

extension ProfileClient {
	static let previewValueTwoPersonas = with(noop) {
		$0.getAccounts = {
			NonEmpty(.previewValue0, .previewValue1)
		}
		$0.getPersonas = {
			[.previewValue0, .previewValue1]
		}
		$0.getConnectedDapps = {
			var dapp = OnNetwork.ConnectedDapp(
				networkID: .nebunet,
				dAppDefinitionAddress: try! .init(address: "DappDefinitionAddress"),
				displayName: .init(rawValue: "something")!
			)
			dapp.referencesToAuthorizedPersonas = [
				.init(
					identityAddress: OnNetwork.Persona.previewValue1.address,
					fieldIDs: [],
					lastLogin: .now,
					sharedAccounts: try! .init(
						accountsReferencedByAddress: [try! AccountAddress(address: "abc")],
						forRequest: .exactly(1)
					)
				),
			]
			return [dapp]
		}
	}
}
#endif

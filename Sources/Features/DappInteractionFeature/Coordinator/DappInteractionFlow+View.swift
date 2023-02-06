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
			}
			.navigationTransition(.slide)
			.onAppear { ViewStore(store.stateless).send(.view(.appeared)) }
		}

		func destination(
			for store: StoreOf<DappInteractionFlow.Destinations>
		) -> some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /DappInteractionFlow.Destinations.State.login,
					action: DappInteractionFlow.Destinations.Action.login,
					then: { LoginRequest.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.State.permission,
					action: DappInteractionFlow.Destinations.Action.permission,
					then: { Permission.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.State.chooseAccounts,
					action: DappInteractionFlow.Destinations.Action.chooseAccounts,
					then: { ChooseAccounts.View(store: $0) }
				)
				CaseLet(
					state: /DappInteractionFlow.Destinations.State.signAndSubmitTransaction,
					action: DappInteractionFlow.Destinations.Action.signAndSubmitTransaction,
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
					interaction: .init(
						id: .previewValue0,
						items: .request(.authorized(.init(
							auth: .login(.init(challenge: nil)),
							oneTimeAccounts: .previewValue,
							ongoingAccounts: .init(
								numberOfAccounts: .atLeast(2),
								requiresProofOfOwnership: false
							)
						))),
						metadata: .previewValue
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
					sharedAccounts: .init(
						mode: .atLeast([try! AccountAddress(address: "abc")])
					)
				),
			]
			return [dapp]
		}
	}
}
#endif

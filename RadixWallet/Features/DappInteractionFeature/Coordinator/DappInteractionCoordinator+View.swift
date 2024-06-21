import ComposableArchitecture
import SwiftUI

// MARK: - DappInteractionCoordinator.View
extension DappInteractionCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionCoordinator>

		var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.childState, action: { $0 })) { state in
					switch state {
					case .loading:
						CaseLet(
							/DappInteractionCoordinator.State.ChildState.loading,
							action: { DappInteractionCoordinator.Action.child(.loading($0)) },
							then: { DappInteractionLoading.View(store: $0) }
						)
					case .originVerification:
						CaseLet(
							/DappInteractionCoordinator.State.ChildState.originVerification,
							action: { DappInteractionCoordinator.Action.child(.originVerification($0)) },
							then: { DappInteractionVerifyDappOrigin.View(store: $0) }
						)
					case .flow:
						CaseLet(
							/DappInteractionCoordinator.State.ChildState.flow,
							action: { DappInteractionCoordinator.Action.child(.flow($0)) },
							then: { DappInteractionFlow.View(store: $0) }
						)
					}
				}
			}
			.alert(
				store: store.scope(
					state: \.$errorAlert,
					action: { .view(.malformedInteractionErrorAlert($0)) }
				)
			)
			.presentsLoadingViewOverlay()
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct DappInteractionCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		DappInteractionCoordinator.View(
			store: .init(
				initialState: .init(
					request: RequestEnvelope(route: .wallet, interaction: .previewValueAllRequests(), requiresOriginValidation: false)
				)
			) {
				DappInteractionCoordinator()
					.dependency(\.accountsClient, .previewValueTwoAccounts())
					//  .dependency(\.authorizedDappsClient, .previewValueOnePersona())
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: true))
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: false))
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataSuccess)
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataFailure)
			}
		)
		.presentsLoadingViewOverlay()
	}
}

extension GatewayAPIClient {
	// TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
	static let previewValueDappMetadataSuccess = update(previewValue) {
		$0.getEntityMetadata = { @Sendable _, _ in
			try await Task.sleep(for: .seconds(2))
			return GatewayAPI.EntityMetadataCollection(
				items: []
			)
		}
	}

	// TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
	static let previewValueDappMetadataFailure = update(previewValue) {
		$0.getEntityMetadata = { @Sendable _, _ in
			try await Task.sleep(for: .seconds(2))
			throw NoopError()
		}
	}
}
#endif

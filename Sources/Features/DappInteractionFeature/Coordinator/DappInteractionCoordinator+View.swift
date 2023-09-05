import FeaturePrelude

// MARK: - DappInteractionCoordinator.View
extension DappInteractionCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionCoordinator>

		var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.childState)) { state in
					switch state {
					case .loading:
						CaseLet(
							state: /DappInteractionCoordinator.State.ChildState.loading,
							action: { DappInteractionCoordinator.Action.child(.loading($0)) },
							then: { DappInteractionLoading.View(store: $0) }
						)
					case .flow:
						CaseLet(
							state: /DappInteractionCoordinator.State.ChildState.flow,
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
import GatewayAPI
import SwiftUI // NB: necessary for previews to appear

struct DappInteractionCoordinator_Previews: PreviewProvider {
	static var previews: some View {
		DappInteractionCoordinator.View(
			store: .init(
				initialState: .init(
					interaction: .previewValueAllRequests(
						auth: .login(.withoutChallenge)
					)
				),
				reducer: DappInteractionCoordinator()
					.dependency(\.accountsClient, .previewValueTwoAccounts())
//					.dependency(\.authorizedDappsClient, .previewValueOnePersona())
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: true))
					.dependency(\.personasClient, .previewValueTwoPersonas(existing: false))
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataSuccess)
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataFailure)
			)
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

import FeaturePrelude

// MARK: - DappInteractionCoordinator.View
extension DappInteractionCoordinator {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DappInteractionCoordinator>

		var body: some SwiftUI.View {
			ZStack {
				SwitchStore(store.scope(state: \.childState)) {
					CaseLet(
						state: /DappInteractionCoordinator.State.ChildState.loading,
						action: { DappInteractionCoordinator.Action.child(.loading($0)) },
						then: { DappInteractionLoading.View(store: $0) }
					)
					CaseLet(
						state: /DappInteractionCoordinator.State.ChildState.flow,
						action: { DappInteractionCoordinator.Action.child(.flow($0)) },
						then: { DappInteractionFlow.View(store: $0) }
					)
				}
			}
			.alert(
				store.scope(
					state: \.errorAlert,
					action: { .view(.malformedInteractionErrorAlert($0)) }
				),
				dismiss: .systemDismissed
			)
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
				initialState: .init(interaction: .previewValueNoRequestItems),
				reducer: DappInteractionCoordinator()
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataSuccess)
					.dependency(\.gatewayAPIClient, .previewValueDappMetadataFailure)
			)
		)
		.presentsLoadingViewOverlay()
	}
}

extension GatewayAPIClient {
	// TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
	static let previewValueDappMetadataSuccess = with(previewValue) {
		$0.accountMetadataByAddress = { @Sendable _ in
			try await Task.sleep(for: .seconds(2))
			return GatewayAPI.EntityMetadataResponse(
				ledgerState: .previewValue,
				address: "abc",
				metadata: .init(items: [])
			)
		}
	}

	// TODO: should be with(noop) — see GatewayAPIClient+Mock.swift for deets.
	static let previewValueDappMetadataFailure = with(previewValue) {
		$0.accountMetadataByAddress = { @Sendable _ in
			try await Task.sleep(for: .seconds(2))
			throw NoopError()
		}
	}
}
#endif

import ComposableArchitecture
import SwiftUI

extension InteractionReviewCommon {
	@Reducer
	struct Proofs: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			var proofs: IdentifiedArrayOf<ProofEntity>

			init(proofs: IdentifiedArrayOf<ProofEntity>) {
				self.proofs = proofs
			}
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Sendable, Equatable {
			case infoTapped
			case proofTapped(ProofEntity)
		}

		enum DelegateAction: Sendable, Equatable {
			case showAsset(ProofEntity)
		}

		var body: some ReducerOf<Self> {
			Reduce(core)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .infoTapped:
				.none
			case let .proofTapped(proof):
				.send(.delegate(.showAsset(proof)))
			}
		}
	}

	struct ProofEntity: Sendable, Identifiable, Hashable {
		var id: ResourceBalance { resourceBalance }
		let resourceBalance: ResourceBalance
	}
}

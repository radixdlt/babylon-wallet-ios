import ComposableArchitecture
import SwiftUI

extension InteractionReviewCommon {
	struct Proofs: Sendable, FeatureReducer {
		struct State: Sendable, Hashable {
			var proofs: IdentifiedArrayOf<ProofEntity>

			init(proofs: IdentifiedArrayOf<ProofEntity>) {
				self.proofs = proofs
			}
		}

		enum ViewAction: Sendable, Equatable {
			case infoTapped
			case proofTapped(ProofEntity)
		}

		enum DelegateAction: Sendable, Equatable {
			case showAsset(ProofEntity)
		}

		init() {}

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

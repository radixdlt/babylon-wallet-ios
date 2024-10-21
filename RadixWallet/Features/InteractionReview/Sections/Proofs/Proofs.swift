import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReview.Proofs
extension InteractionReview {
	@Reducer
	struct Proofs: Sendable, FeatureReducer {
		@ObservableState
		struct State: Sendable, Hashable {
			let kind: InteractionReview.Kind
			let proofs: IdentifiedArrayOf<ProofEntity>
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
}

// MARK: - InteractionReview.ProofEntity
extension InteractionReview {
	struct ProofEntity: Sendable, Identifiable, Hashable {
		var id: ResourceBalance { resourceBalance }
		let resourceBalance: ResourceBalance
	}
}

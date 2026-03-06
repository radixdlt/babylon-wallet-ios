import ComposableArchitecture
import SwiftUI

// MARK: - InteractionReview.Proofs
extension InteractionReview {
	@Reducer
	struct Proofs: FeatureReducer {
		@ObservableState
		struct State: Hashable {
			let kind: InteractionReview.Kind
			let proofs: IdentifiedArrayOf<ProofEntity>
		}

		typealias Action = FeatureAction<Self>

		enum ViewAction: Equatable {
			case infoTapped
			case proofTapped(ProofEntity)
		}

		enum DelegateAction: Equatable {
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
	struct ProofEntity: Identifiable, Hashable {
		var id: KnownResourceBalance {
			resourceBalance
		}

		let resourceBalance: KnownResourceBalance
	}
}

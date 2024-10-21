import ComposableArchitecture
import Sargon
import SwiftUI

typealias InteractionReviewPools = InteractionReviewDapps<PoolAddress>
typealias InteractionReviewDappsUsed = InteractionReviewDapps<ComponentAddress>

// MARK: - InteractionReviewDapps
struct InteractionReviewDapps<AddressType: AddressProtocol>: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var knownDapps: IdentifiedArrayOf<InteractionReview.DappEntity>
		var unknownDapps: IdentifiedArrayOf<AddressType>
		var isExpanded: Bool = true
		let unknownTitle: String

		init(knownDapps: IdentifiedArrayOf<InteractionReview.DappEntity>, unknownDapps: IdentifiedArrayOf<AddressType>, unknownTitle: (Int) -> String) {
			self.knownDapps = knownDapps
			self.unknownDapps = unknownDapps
			self.unknownTitle = unknownTitle(unknownDapps.count)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case dappTapped(InteractionReview.DappEntity.ID)
		case unknownsTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case openDapp(InteractionReview.DappEntity.ID)
		case openUnknownAddresses(IdentifiedArrayOf<AddressType>)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .dappTapped(id):
			.send(.delegate(.openDapp(id)))

		case .unknownsTapped:
			.send(.delegate(.openUnknownAddresses(state.unknownDapps)))
		}
	}
}

// MARK: - InteractionReview.DappEntity
extension InteractionReview {
	struct DappEntity: Sendable, Identifiable, Hashable {
		let id: DappDefinitionAddress
		let metadata: OnLedgerEntity.Metadata
	}
}

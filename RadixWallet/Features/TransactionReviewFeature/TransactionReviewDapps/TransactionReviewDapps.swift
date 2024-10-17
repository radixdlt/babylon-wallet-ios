import ComposableArchitecture
import Sargon
import SwiftUI

typealias TransactionReviewPools = TransactionReviewDapps<PoolAddress>
typealias TransactionReviewDappsUsed = TransactionReviewDapps<ComponentAddress>

// MARK: - TransactionReviewDapps
struct TransactionReviewDapps<AddressType: AddressProtocol>: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>
		var unknownDapps: IdentifiedArrayOf<AddressType>
		var isExpanded: Bool = true
		let unknownTitle: String

		init(knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>, unknownDapps: IdentifiedArrayOf<AddressType>, unknownTitle: (Int) -> String) {
			self.knownDapps = knownDapps
			self.unknownDapps = unknownDapps
			self.unknownTitle = unknownTitle(unknownDapps.count)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case dappTapped(TransactionReview.DappEntity.ID)
		case unknownsTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case openDapp(TransactionReview.DappEntity.ID)
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

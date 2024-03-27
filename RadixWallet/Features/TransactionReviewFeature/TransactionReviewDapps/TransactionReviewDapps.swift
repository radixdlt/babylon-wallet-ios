import ComposableArchitecture
import Sargon
import SwiftUI

public typealias TransactionReviewPools = TransactionReviewDapps<PoolAddress>
public typealias TransactionReviewDappsUsed = TransactionReviewDapps<ComponentAddress>

// MARK: - TransactionReviewDapps
public struct TransactionReviewDapps<AddressType: AddressProtocol>: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>
		public var unknownDapps: IdentifiedArrayOf<AddressType>
		public var isExpanded: Bool = true
		public let unknownTitle: String

		public init(knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>, unknownDapps: IdentifiedArrayOf<AddressType>, unknownTitle: (Int) -> String) {
			self.knownDapps = knownDapps
			self.unknownDapps = unknownDapps
			self.unknownTitle = unknownTitle(unknownDapps.count)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case dappTapped(TransactionReview.DappEntity.ID)
		case unknownsTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDapp(TransactionReview.DappEntity.ID)
		case openUnknownAddresses(IdentifiedArrayOf<AddressType>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .dappTapped(id):
			.send(.delegate(.openDapp(id)))

		case .unknownsTapped:
			.send(.delegate(.openUnknownAddresses(state.unknownDapps)))
		}
	}
}

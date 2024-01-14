import ComposableArchitecture
import SwiftUI

public typealias TransactionReviewPools = TransactionReviewDapps<ResourcePoolEntityType>
public typealias TransactionReviewDappsUsed = TransactionReviewDapps<ComponentEntityType>

// MARK: - TransactionReviewDapps
public struct TransactionReviewDapps<Kind: SpecificEntityType>: Sendable, FeatureReducer {
	public typealias AddressType = SpecificAddress<Kind>

	public struct State: Sendable, Hashable {
		public var knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>
		public var unknownDapps: IdentifiedArrayOf<AddressType>
		public var isExpanded: Bool = true

		public init(knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>, unknownDapps: IdentifiedArrayOf<AddressType>) {
			self.knownDapps = knownDapps
			self.unknownDapps = unknownDapps
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case dappTapped(TransactionReview.DappEntity.ID)
		case unknownComponentsTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDapp(TransactionReview.DappEntity.ID)
		case openUnknownComponents(IdentifiedArrayOf<AddressType>)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .dappTapped(id):
			.send(.delegate(.openDapp(id)))

		case .unknownComponentsTapped:
			.send(.delegate(.openUnknownComponents(state.unknownDapps)))
		}
	}
}

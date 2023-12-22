import ComposableArchitecture
import SwiftUI

// MARK: - TransactionReviewDappsUsed
public struct TransactionReviewDappsUsed: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var isExpanded: Bool
		public var knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>
		public var unknownDapps: IdentifiedArrayOf<TransactionReview.UnknownDapp>

		public init(isExpanded: Bool, knownDapps: IdentifiedArrayOf<TransactionReview.DappEntity>, unknownDapps: IdentifiedArrayOf<TransactionReview.UnknownDapp>) {
			self.isExpanded = isExpanded
			self.knownDapps = knownDapps
			self.unknownDapps = unknownDapps
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case expandTapped
		case dappTapped(TransactionReview.DappEntity.ID)
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDapp(TransactionReview.DappEntity.ID)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .expandTapped:
			state.isExpanded.toggle()
			return .none

		case let .dappTapped(id):
			return .send(.delegate(.openDapp(id)))
		}
	}
}

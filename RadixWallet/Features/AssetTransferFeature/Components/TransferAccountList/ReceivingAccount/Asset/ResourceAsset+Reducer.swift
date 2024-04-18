import ComposableArchitecture
import SwiftUI

// MARK: - ResourceAsset
// Higher order reducer composing all types of assets that can be transferred
public struct ResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		@CasePathable
		public enum Kind: Sendable, Hashable {
			case fungibleAsset(FungibleResourceAsset.State)
			case nonFungibleAsset(NonFungibleResourceAsset.State)

			public var fungible: FungibleResourceAsset.State? {
				switch self {
				case let .fungibleAsset(asset): asset
				case .nonFungibleAsset: nil
				}
			}

			public var nonFungible: NonFungibleResourceAsset.State? {
				switch self {
				case let .nonFungibleAsset(asset): asset
				case .fungibleAsset: nil
				}
			}
		}

		public typealias ID = String
		public var id: ID {
			switch self.kind {
			case let .fungibleAsset(asset):
				asset.id
			case let .nonFungibleAsset(asset):
				asset.id
			}
		}

		public var kind: Kind
		public var additionalSignatureRequired: Bool = false
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.Action)
		case nonFungibleAsset(NonFungibleResourceAsset.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case fungibleAsset(FungibleResourceAsset.DelegateAction)
		case removed
	}

	public enum ViewAction: Equatable, Sendable {
		case removeTapped
	}

	public var body: some ReducerOf<Self> {
		Scope(state: \.kind, action: \.child) {
			Scope(state: \.fungibleAsset, action: \.fungibleAsset) {
				FungibleResourceAsset()
			}
			Scope(state: \.nonFungibleAsset, action: \.nonFungibleAsset) {
				NonFungibleResourceAsset()
			}
		}

		Reduce(core)
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .fungibleAsset(.delegate(action)):
			.send(.delegate(.fungibleAsset(action)))
		default:
			.none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			.send(.delegate(.removed))
		}
	}
}

extension ResourceAsset.State {
	mutating func unsetFocus() {
		if case var .fungibleAsset(state) = self.kind, state.focused {
			state.focused = false
			self.kind = .fungibleAsset(state)
		}
	}
}

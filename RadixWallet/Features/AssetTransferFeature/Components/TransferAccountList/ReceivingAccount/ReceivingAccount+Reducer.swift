import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ReceivingAccount
public struct ReceivingAccount: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = UUID
		public let id = ID()

		public var recipient: AccountOrAddressOf?
		public var assets: IdentifiedArrayOf<ResourceAsset.State>
		public var canBeRemoved: Bool

		public init(
			recipient: AccountOrAddressOf?,
			assets: IdentifiedArrayOf<ResourceAsset.State>,
			canBeRemovedWhenEmpty: Bool
		) {
			self.recipient = recipient
			self.assets = assets
			self.canBeRemoved = canBeRemovedWhenEmpty
		}

		public static func empty(canBeRemovedWhenEmpty: Bool) -> Self {
			.init(recipient: nil, assets: [], canBeRemovedWhenEmpty: canBeRemovedWhenEmpty)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case chooseAccountTapped
		case addAssetTapped
		case removeTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case remove
		case chooseAccount
		case addAssets
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case row(id: ResourceAsset.State.ID, child: ResourceAsset.Action)
	}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.assets, action: /Action.child .. ChildAction.row) {
				ResourceAsset()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			.send(.delegate(.remove))
		case .addAssetTapped:
			.send(.delegate(.addAssets))
		case .chooseAccountTapped:
			.send(.delegate(.chooseAccount))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .row(id: id, child: .delegate(.removed)):
			state.assets.remove(id: id)
			return .none
		default:
			return .none
		}
	}
}

extension AccountOrAddressOf {
	var name: String {
		switch self {
		case let .profileAccount(account):
			account.displayName.value
		case .addressOfExternalAccount:
			L10n.Common.account
		}
	}

	var identifer: LedgerIdentifiable {
		switch self {
		case let .profileAccount(value: account):
			.address(.account(account.address, isLedgerHWAccount: account.isLedgerControlled))
		case let .addressOfExternalAccount(address):
			.address(.account(address, isLedgerHWAccount: false))
		}
	}

	var gradient: Gradient {
		switch self {
		case let .profileAccount(value: account):
			.init(account.appearanceID)
		case .addressOfExternalAccount:
			.init(colors: [.app.gray2])
		}
	}

	var isUserAccount: Bool {
		guard case .profileAccount = self else {
			return false
		}

		return true
	}
}

extension ResourceAsset.State {
	var resourceAddress: ResourceAddress {
		switch kind {
		case let .fungibleAsset(state):
			state.resource.resourceAddress
		case let .nonFungibleAsset(state):
			state.resource.resourceAddress
		}
	}
}

extension Collection<ResourceAsset.State> {
	var fungibleAssets: [FungibleResourceAsset.State] {
		map(\.kind).compactMap(/ResourceAsset.State.Kind.fungibleAsset)
	}

	var nonFungibleAssets: [NonFungibleResourceAsset.State] {
		map(\.kind).compactMap(/ResourceAsset.State.Kind.nonFungibleAsset)
	}
}

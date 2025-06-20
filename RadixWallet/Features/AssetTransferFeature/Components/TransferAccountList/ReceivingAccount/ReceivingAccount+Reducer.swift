import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - ReceivingAccount
struct ReceivingAccount: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, Identifiable {
		typealias ID = UUID
		let id = ID()

		var recipient: TransferRecipient?
		var assets: IdentifiedArrayOf<ResourceAsset.State>
		var canBeRemoved: Bool

		init(
			recipient: TransferRecipient?,
			assets: IdentifiedArrayOf<ResourceAsset.State>,
			canBeRemovedWhenEmpty: Bool
		) {
			self.recipient = recipient
			self.assets = assets
			self.canBeRemoved = canBeRemovedWhenEmpty
		}

		static func empty(canBeRemovedWhenEmpty: Bool) -> Self {
			.init(recipient: nil, assets: [], canBeRemovedWhenEmpty: canBeRemovedWhenEmpty)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case chooseAccountTapped
		case addAssetTapped
		case removeTapped
	}

	enum DelegateAction: Sendable, Equatable {
		case remove
		case chooseAccount
		case addAssets
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case row(id: ResourceAsset.State.ID, child: ResourceAsset.Action)
	}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.forEach(\.assets, action: /Action.child .. ChildAction.row) {
				ResourceAsset()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .removeTapped:
			.send(.delegate(.remove))
		case .addAssetTapped:
			.send(.delegate(.addAssets))
		case .chooseAccountTapped:
			.send(.delegate(.chooseAccount))
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case let .row(id: id, child: .delegate(.removed)):
			state.assets.remove(id: id)
			return .none
		default:
			return .none
		}
	}
}

extension ReceivingAccount.State {
	var isDepositEnabled: Bool {
		assets.allSatisfy(\.isDepositEnabled)
	}

	var isLoadingDepositStatus: Bool {
		assets.contains(where: { $0.depositStatus == .loading })
	}

	mutating func setAllDepositStatus(_ status: Loadable<DepositStatus>) {
		assets.mutateAll { asset in
			asset.depositStatus = status
		}
	}

	mutating func updateDepositStatus(values: DepositStatusPerResources) {
		assets.mutateAll { asset in
			if let value = values[id: asset.resourceAddress] {
				asset.depositStatus = .success(value.depositStatus)
			}
		}
	}
}

extension TransferRecipient {
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

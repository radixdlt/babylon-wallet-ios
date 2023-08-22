import EngineKit
import FeaturePrelude

// MARK: - AddAsset
public struct AddAsset: FeatureReducer {
	public struct State: Hashable, Sendable {
		var mode: ResourcesListMode
		let alreadyAddedResources: OrderedSet<ThirdPartyDeposits.DepositAddress>

		var resourceAddress: String = ""
		var resourceAddressFieldFocused: Bool = false

		var validatedResourceAddress: ThirdPartyDeposits.DepositAddress? {
			guard !resourceAddress.isEmpty else {
				return nil
			}

			return .init(raw: resourceAddress)
		}
	}

	public enum ViewAction: Hashable {
		case addAssetTapped(ThirdPartyDeposits.DepositAddress)
		case resourceAddressChanged(String)
		case exceptionRuleChanged(ResourcesListMode.ExceptionRule)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Hashable {
		case addAddress(ResourcesListMode, ThirdPartyDeposits.DepositAddress)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .addAssetTapped(resourceAddress):
			return .send(.delegate(.addAddress(state.mode, resourceAddress)))

		case let .resourceAddressChanged(address):
			state.resourceAddress = address
			return .none

		case let .exceptionRuleChanged(rule):
			state.mode = .allowDenyAssets(rule)
			return .none

		case let .focusChanged(focus):
			state.resourceAddressFieldFocused = focus
			return .none
		}
	}
}

extension ThirdPartyDeposits.DepositAddress {
	init?(raw: String) {
		if let asResourceAddress = try? ResourceAddress(validatingAddress: raw) {
			self = .resourceAddress(asResourceAddress)
			return
		}

		if let asNFTId = try? NonFungibleGlobalId(nonFungibleGlobalId: raw) {
			self = .nonFungibleGlobalID(asNFTId)
			return
		}

		return nil
	}
}

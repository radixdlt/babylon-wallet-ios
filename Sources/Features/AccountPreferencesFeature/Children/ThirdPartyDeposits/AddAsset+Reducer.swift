import EngineKit
import FeaturePrelude

// MARK: - AddAsset
public struct AddAsset: FeatureReducer {
	public struct State: Hashable, Sendable {
		var mode: ResourcesListMode
		let alreadyAddedResources: OrderedSet<Resource.Address>

		var resourceAddress: String = ""
		var resourceAddressFieldFocused: Bool = false

		var validatedResourceAddress: Resource.Address? {
			guard !resourceAddress.isEmpty else {
				return nil
			}

			switch mode {
			case let .allowDenyAssets(exceptionRule):
				return try? .assetException(.init(address: .init(validatingAddress: resourceAddress), exceptionRule: exceptionRule))
			case .allowDepositors:
				return ThirdPartyDeposits.DepositorAddress(raw: resourceAddress).map { .allowedDepositor($0) }
			}
		}
	}

	public enum ViewAction: Hashable {
		case addAssetTapped(Resource.Address)
		case resourceAddressChanged(String)
		case exceptionRuleChanged(ResourcesListMode.ExceptionRule)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Hashable {
		case addAddress(ResourcesListMode, Resource.Address)
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

extension ThirdPartyDeposits.DepositorAddress {
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

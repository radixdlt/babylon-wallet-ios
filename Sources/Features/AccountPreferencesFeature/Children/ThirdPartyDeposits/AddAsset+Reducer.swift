import EngineKit
import FeaturePrelude

public struct AddAsset: FeatureReducer {
	public struct State: Hashable, Sendable {
		var type: AllowDenyAssets.State.List
		var resourceAddress: String
		var resourceAddressFieldFocused: Bool = false

		let currentAllowList: Set<ResourceAddress>
		let currentDenyList: Set<ResourceAddress>

		var validatedResourceAddress: ResourceAddress? {
			guard !resourceAddress.isEmpty else {
				return nil
			}

			guard let address = try? ResourceAddress(validatingAddress: resourceAddress) else {
				return nil
			}

			return address
		}
	}

	public enum ViewAction: Hashable {
		case addAssetTapped(ResourceAddress)
		case resourceAddressChanged(String)
		case addTypeChanged(AllowDenyAssets.State.List)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Hashable {
		case addAsset(AllowDenyAssets.State.List, ResourceAddress)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .addAssetTapped(resourceAddress):
			return .send(.delegate(.addAsset(state.type, resourceAddress)))
		case let .resourceAddressChanged(address):
			state.resourceAddress = address
			return .none
		case let .addTypeChanged(type):
			state.type = type
			return .none
		case let .focusChanged(focus):
			state.resourceAddressFieldFocused = focus
			return .none
		}
	}
}

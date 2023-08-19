import EngineKit
import FeaturePrelude

// MARK: - AddAsset
public struct AddAsset: FeatureReducer {
	public struct State: Hashable, Sendable {
		var type: AllowDenyAssets.State.List

		var resourceAddress: String
		var resourceAddressFieldFocused: Bool = false

		let alreadyAddedResources: Set<DepositAddress>

		var validatedResourceAddress: DepositAddress? {
			guard !resourceAddress.isEmpty else {
				return nil
			}

			return .init(raw: resourceAddress)
		}
	}

	public enum ViewAction: Hashable {
		case addAssetTapped(DepositAddress)
		case resourceAddressChanged(String)
		case addTypeChanged(AllowDenyAssets.State.List)
		case focusChanged(Bool)
	}

	public enum DelegateAction: Hashable {
		case addAddress(AllowDenyAssets.State.List, DepositAddress)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .addAssetTapped(resourceAddress):
			return .send(.delegate(.addAddress(state.type, resourceAddress)))

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

extension DepositAddress {
	init?(raw: String) {
		if let asResourceAddress = try? ResourceAddress(validatingAddress: raw) {
			self = .resource(asResourceAddress)
			return
		}

		if let asNFTId = try? NonFungibleGlobalId(nonFungibleGlobalId: raw) {
			self = .nftID(asNFTId)
			return
		}

		return nil
	}
}

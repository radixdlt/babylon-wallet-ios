import EngineKit
import FeaturePrelude

// MARK: - AddAsset
public struct AddAsset: FeatureReducer, Sendable {
	public struct State: Hashable, Sendable {
		var mode: ResourcesListMode
		let alreadyAddedResources: OrderedSet<ResourceViewState.Address>

		var resourceAddress: String = ""
		var resourceAddressFieldFocused: Bool = false

		var validatedResourceAddress: ResourceViewState.Address? {
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

	public enum ViewAction: Hashable, Sendable {
		case addAssetTapped(ResourceViewState.Address)
		case resourceAddressChanged(String)
		case exceptionRuleChanged(ResourcesListMode.ExceptionRule)
		case focusChanged(Bool)
		case closeTapped
	}

	public enum DelegateAction: Hashable, Sendable {
		case addAddress(ResourcesListMode, ResourceViewState.Address)
	}

	@Dependency(\.dismiss) var dismiss

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

		case .closeTapped:
			return .run { _ in
				await dismiss()
			}
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

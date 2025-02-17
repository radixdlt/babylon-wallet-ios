import ComposableArchitecture
import SwiftUI

// MARK: - AddAsset
struct AddAsset: FeatureReducer, Sendable {
	struct State: Hashable, Sendable {
		var mode: ResourcesListMode
		let alreadyAddedResources: OrderedSet<ResourceViewState.Address>
		let networkID: NetworkID

		var resourceAddress: String = ""
		var resourceAddressFieldFocused: Bool = false

		enum AddressValidation: Sendable, Hashable {
			case valid(ResourceViewState.Address)
			case wrongNetwork(ResourceViewState.Address, incorrectNetwork: UInt8)
			case alreadyAdded
			case invalid

			var validAddress: ResourceViewState.Address? {
				guard case let .valid(address) = self else {
					return nil
				}

				return address
			}
		}

		var validatedResourceAddress: AddressValidation {
			guard !resourceAddress.isEmpty else {
				return .invalid
			}

			var address: ResourceViewState.Address?

			switch mode {
			case let .allowDenyAssets(exceptionRule):
				address = try? .assetException(.init(address: .init(validatingAddress: resourceAddress), exceptionRule: exceptionRule))
			case .allowDepositors:
				if let nonFungibleGlobalId = try? NonFungibleGlobalId(resourceAddress) {
					address = .allowedDepositor(.nonFungible(value: nonFungibleGlobalId))
				} else if let resourceAddress = try? ResourceAddress(validatingAddress: resourceAddress) {
					address = .allowedDepositor(.resource(value: resourceAddress))
				}
			}

			guard let address else {
				return .invalid
			}

			guard address.resourceAddress.networkID == networkID else {
				// On wrong network
				return .wrongNetwork(address, incorrectNetwork: address.resourceAddress.networkID.rawValue)
			}

			guard !alreadyAddedResources.contains(where: { $0.resourceAddress == address.resourceAddress }) else {
				return .alreadyAdded
			}

			return .valid(address)
		}
	}

	enum ViewAction: Hashable, Sendable {
		case addAssetTapped(ResourceViewState.Address)
		case resourceAddressChanged(String)
		case exceptionRuleChanged(ResourcesListMode.ExceptionRule)
		case focusChanged(Bool)
		case closeTapped
	}

	enum DelegateAction: Hashable, Sendable {
		case addAddress(ResourcesListMode, ResourceViewState.Address)
	}

	@Dependency(\.dismiss) var dismiss

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
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

import ComposableArchitecture
import SwiftUI

extension FungibleAssetList.Section {
	struct Row: FeatureReducer {
		struct State: Hashable, Identifiable {
			typealias ID = ResourceAddress
			var id: ID {
				token.resourceAddress
			}

			var token: OnLedgerEntity.OwnedFungibleResource
			var isXRD: Bool
			var isSelected: Bool?

			init(
				xrdToken: OnLedgerEntity.OwnedFungibleResource,
				isSelected: Bool? = nil
			) {
				self.init(
					token: xrdToken,
					isXRD: true,
					isSelected: isSelected
				)
			}

			init(
				nonXRDToken: OnLedgerEntity.OwnedFungibleResource,
				isSelected: Bool? = nil
			) {
				self.init(
					token: nonXRDToken,
					isXRD: false,
					isSelected: isSelected
				)
			}

			init(
				token: OnLedgerEntity.OwnedFungibleResource,
				isXRD: Bool,
				isSelected: Bool? = nil
			) {
				self.token = token
				self.isXRD = isXRD
				self.isSelected = isSelected
			}
		}

		enum ViewAction: Equatable {
			case tapped
		}

		enum DelegateAction: Equatable {
			case selected(OnLedgerEntity.OwnedFungibleResource)
		}

		func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
			switch viewAction {
			case .tapped:
				if state.isSelected != nil {
					state.isSelected?.toggle()
					return .none
				}
				return .send(.delegate(.selected(state.token)))
			}
		}
	}
}

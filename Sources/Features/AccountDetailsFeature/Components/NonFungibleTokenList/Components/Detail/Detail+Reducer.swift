// import FeaturePrelude
//
//// MARK: - NonFungibleTokenList.Detail
// extension NonFungibleTokenList {
//	// MARK: - NonFungibleTokenDetails
//	public struct Detail: Sendable, FeatureReducer {
//		public struct State: Sendable, Hashable {
//                        var token: AccountPortfolio.NonFungibleToken
//		}
//
//		public enum ViewAction: Sendable, Equatable {
//			case closeButtonTapped
//			case copyAddressButtonTapped(String)
//		}
//
//		public enum DelegateAction: Sendable, Equatable {
//			case dismiss
//		}
//
//		@Dependency(\.pasteboardClient) var pasteboardClient
//
//		public init() {}
//
//		public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
//			switch viewAction {
//			case .closeButtonTapped:
//				return .send(.delegate(.dismiss))
//			case let .copyAddressButtonTapped(address):
//				return .run { _ in
//					pasteboardClient.copyString(address)
//				}
//			}
//		}
//	}
// }

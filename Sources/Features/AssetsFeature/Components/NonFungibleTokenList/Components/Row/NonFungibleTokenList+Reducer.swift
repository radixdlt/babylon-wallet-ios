import FeaturePrelude
//
// extension NonFungibleTokenList.Row {
//        public struct NonFungbileTokenList: Sendable, FeatureReducer {
//                public struct State: Sendable, Hashable, Identifiable {
//                        public var id: AccountPortfolio.NonFungibleResource.NonFungibleToken.ID {
//                                token.id
//                        }
//
//                        public let token: AccountPortfolio.NonFungibleResource.Non
//
//                        public init(
//                                token: AccountPortfolio.NonFungibleResource.NonFungibleToken
//                        ) {
//                                self.token = token
//                        }
//                }
//
//                public enum ViewAction: Sendable, Equatable {
//                        case tapped
//                }
//
//                public enum DelegateAction: Sendable, Equatable {
//                        case handleTapped
//                }
//
//                public init() {}
//
//                public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
//                        switch viewAction {
//                        case .tapped:
//                                return .send(.delegate(.handleTapped))
//                        }
//                }
//        }
// }

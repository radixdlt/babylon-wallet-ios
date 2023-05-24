// import FeaturePrelude
//
// extension NonFungibleTokenList.Row.NonFungbileTokenList {
//        public typealias ViewState = State
//
//        @MainActor
//        public struct View: SwiftUI.View {
//                private let spacing: CGFloat = .small3 / 2
//
//                private let store: StoreOf<NonFungibleTokenList>
//
//                public init(store: StoreOf<NonFungibleTokenList>) {
//                        self.store = store
//                }
//
//                public var body: some SwiftUI.View {
//                        WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
//                                ForEach
//                                HStack {
//                                        NFTIDView(
//                                                id: viewStore.token.id.toUserFacingString,
//                                                name: viewStore.token.name,
//                                                description: viewStore.token.description,
//                                                thumbnail: viewStore.token.keyImageURL,
//                                                metadata: viewStore.token.metadata
//                                        )
//                                        CheckmarkView(appearance: .dark, isChecked: Bool.random())
//                                }
//                        }
//                }
//        }
// }

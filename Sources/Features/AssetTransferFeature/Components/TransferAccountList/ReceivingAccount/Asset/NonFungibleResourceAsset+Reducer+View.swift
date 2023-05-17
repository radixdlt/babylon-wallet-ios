import FeaturePrelude

// MARK: - NonFungibleResourceAsset
public struct NonFungibleResourceAsset: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public typealias ID = ResourceAddress
		public var id: ID {
			resourceAddress
		}

		public let resourceAddress: ResourceAddress
	}
}

extension NonFungibleResourceAsset {
	public typealias ViewState = State

	@MainActor
	public struct View: SwiftUI.View {
		private let store: Store<NonFungibleResourceAsset.State, Never>
		public init(store: Store<NonFungibleResourceAsset.State, Never>) {
			self.store = store
		}
	}
}

extension NonFungibleResourceAsset.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }) { _ in
		}
	}
}

import ComposableArchitecture

// MARK: - CardCarousel
@Reducer
public struct CardCarousel: FeatureReducer {
	public struct Card: Hashable, Sendable {
		public let title: String
		public let body: String
		public let design: Design

		public enum Design: Hashable, Sendable {
			case shield
		}

		public struct Button: Hashable, Sendable {
			public let title: String
			public let isDestructive: Bool
		}
	}

	@ObservableState
	public struct State: Hashable, Sendable {
		public var card: Card
	}

	public typealias Action = FeatureAction<Self>

	@CasePathable
	public enum ViewAction: Equatable, Sendable {
		case didLaunch
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .didLaunch:
			print("•• didLaunch")
			return .none
		}
	}
}

import SwiftUI

// MARK: CardCarousel.View
extension CardCarousel {
	public struct View: SwiftUI.View {
		let store: StoreOf<CardCarousel>

		public var body: some SwiftUI.View {
			Text("\(store.card.name)")
		}
	}
}

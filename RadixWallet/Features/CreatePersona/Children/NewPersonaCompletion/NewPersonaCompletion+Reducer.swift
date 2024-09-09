import ComposableArchitecture
import SwiftUI

public struct NewPersonaCompletion: Sendable, FeatureReducer {
	public struct State: Sendable & Hashable {
		public let persona: Persona
		public let isFirstOnNetwork: Bool
		public let navigationButtonCTA: CreatePersonaNavigationButtonCTA

		public init(
			persona: Persona,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreatePersonaNavigationButtonCTA
		) {
			self.persona = persona
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		public init(
			persona: Persona,
			config: CreatePersonaConfig
		) {
			self.init(
				persona: persona,
				isFirstOnNetwork: config.personaPrimacy.firstPersonaOnCurrentNetwork,
				navigationButtonCTA: config.navigationButtonCTA
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case goToDestination
	}

	public enum DelegateAction: Sendable, Equatable {
		case completed(Persona)
	}

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .goToDestination:
			.send(.delegate(.completed(state.persona)))
		}
	}
}

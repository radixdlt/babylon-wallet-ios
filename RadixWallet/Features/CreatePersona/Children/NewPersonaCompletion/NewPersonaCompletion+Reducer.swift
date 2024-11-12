import ComposableArchitecture
import SwiftUI

struct NewPersonaCompletion: Sendable, FeatureReducer {
	struct State: Sendable & Hashable {
		let persona: Persona
		let isFirstOnNetwork: Bool
		let navigationButtonCTA: CreatePersonaNavigationButtonCTA

		init(
			persona: Persona,
			isFirstOnNetwork: Bool,
			navigationButtonCTA: CreatePersonaNavigationButtonCTA
		) {
			self.persona = persona
			self.isFirstOnNetwork = isFirstOnNetwork
			self.navigationButtonCTA = navigationButtonCTA
		}

		init(
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

	enum ViewAction: Sendable, Equatable {
		case goToDestination
	}

	enum DelegateAction: Sendable, Equatable {
		case completed(Persona)
	}

	init() {}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .goToDestination:
			.send(.delegate(.completed(state.persona)))
		}
	}
}

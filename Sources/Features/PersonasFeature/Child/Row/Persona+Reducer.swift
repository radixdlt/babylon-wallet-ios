import AuthorizedDAppsFeature
import FeaturePrelude

// MARK: - Persona
public struct Persona: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public var id: Profile.Network.Persona.ID { persona.id }
		public let persona: Profile.Network.Persona

		@PresentationState
		public var details: PersonaDetails.State? = nil

		public init(persona: Profile.Network.Persona) {
			self.persona = persona
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case details(PresentationAction<PersonaDetails.Action>)
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case showDetails
	}

	public init() {}
	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$details, action: /Action.child .. ChildAction.details) {
				PersonaDetails()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .tapped:

			state.details = .init(dAppName: <#T##String#>,
			                      dAppID: <#T##Profile.Network.AuthorizedDapp.ID#>,
			                      networkID: <#T##NetworkID#>,
			                      persona: <#T##Profile.Network.AuthorizedPersonaDetailed#>)

			return .send(.delegate(.showDetails))
		}
	}
}

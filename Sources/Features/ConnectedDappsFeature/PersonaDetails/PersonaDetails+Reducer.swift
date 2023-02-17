import FeaturePrelude
import ProfileClient

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public let dAppName: String
		public let persona: OnNetwork.AuthorizedPersonaDetailed

		public init(dAppName: String, persona: OnNetwork.AuthorizedPersonaDetailed) {
			self.dAppName = dAppName
			self.persona = persona
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case editPersonaTapped
		case accountTapped(AccountAddress)
		case editAccountSharingTapped
		case disconnectPersonaTapped
	}

	public enum DelegateAction: Sendable, Equatable {
		case testTapped
	}

	// MARK: - Reducer

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return .none
		case .editPersonaTapped:
			return .none
		case let .accountTapped(address):
			return .none
		case .editAccountSharingTapped:
			return .none
		case .disconnectPersonaTapped:
			return .send(.delegate(.testTapped))

//			profileClient.updateConnectedDapp

//			return .none
		}
	}
}

extension IdentifiedArrayOf<OnNetwork.Persona.Field> {
	subscript(kind kind: OnNetwork.Persona.Field.Kind) -> OnNetwork.Persona.Field.Value? {
		first { $0.kind == kind }?.value
	}
}

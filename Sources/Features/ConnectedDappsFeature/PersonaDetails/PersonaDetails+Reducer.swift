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
		public let dAppID: OnNetwork.ConnectedDapp.ID
		public let networkID: NetworkID
		public let persona: OnNetwork.AuthorizedPersonaDetailed

		public init(dAppName: String,
		            dAppID: OnNetwork.ConnectedDapp.ID,
		            networkID: NetworkID,
		            persona: OnNetwork.AuthorizedPersonaDetailed)
		{
			self.dAppName = dAppName
			self.dAppID = dAppID
			self.networkID = networkID
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
		case personaDisconnected
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
			print("••• disconnectPersonaTapped")
			let (personaID, dAppID, networkID) = (state.persona.id, state.dAppID, state.networkID)
			return .task {
				try await profileClient.disconnectPersonaFromDapp(personaID, dAppID, networkID)
				return .delegate(.personaDisconnected)
			}
		}
	}
}

extension IdentifiedArrayOf<OnNetwork.Persona.Field> {
	subscript(kind kind: OnNetwork.Persona.Field.Kind) -> OnNetwork.Persona.Field.Value? {
		first { $0.kind == kind }?.value
	}
}

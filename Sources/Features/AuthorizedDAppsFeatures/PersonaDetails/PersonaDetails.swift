import AuthorizedDappsClient
import FeaturePrelude

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.authorizedDappsClient) var authorizedDappsClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public let dAppName: String
		public let dAppID: Profile.Network.AuthorizedDapp.ID
		public let networkID: NetworkID
		public let persona: Profile.Network.AuthorizedPersonaDetailed

		@PresentationState
		public var confirmForgetAlert: AlertState<ViewAction.ConfirmForgetAlert>? = nil
		@PresentationState
		public var destination: Destinations.State? = nil

		public init(
			dAppName: String,
			dAppID: Profile.Network.AuthorizedDapp.ID,
			networkID: NetworkID,
			persona: Profile.Network.AuthorizedPersonaDetailed
		) {
			self.dAppName = dAppName
			self.dAppID = dAppID
			self.networkID = networkID
			self.persona = persona
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case editPersonaTapped
		case accountTapped(AccountAddress)
		case editAccountSharingTapped
		case deauthorizePersonaTapped
		case confirmForgetAlert(PresentationAction<ConfirmForgetAlert>)

		public enum ConfirmForgetAlert: Sendable, Equatable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDeauthorized
	}

	// MARK: - Destinations

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case editPersona(EditPersonaDetails.State)
		}

		public enum Action: Sendable, Equatable {
			case editPersona(EditPersonaDetails.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersonaDetails()
			}
		}
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$confirmForgetAlert, action: /Action.view .. ViewAction.confirmForgetAlert)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .editPersonaTapped:
			state.destination = .editPersona(.init(personaLabel: NonEmptyString("blabla"), existingFields: []))
			return .none

		case let .accountTapped(address):
			return .none

		case .editAccountSharingTapped:
			return .none

		case .deauthorizePersonaTapped:
			state.confirmForgetAlert = .confirmForget
			return .none

		case .confirmForgetAlert(.presented(.confirmTapped)):
			let (personaID, dAppID, networkID) = (state.persona.id, state.dAppID, state.networkID)
			return .run { send in
				try await authorizedDappsClient.deauthorizePersonaFromDapp(personaID, dAppID, networkID)
				await send(.delegate(.personaDeauthorized))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case .confirmForgetAlert:
			return .none
		}
	}
}

extension AlertState<PersonaDetails.ViewAction.ConfirmForgetAlert> {
	static var confirmForget: AlertState {
		AlertState {
			TextState(L10n.PersonaDetails.deauthorizePersonaAlertTitle)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.PersonaDetails.deauthorizePersonaAlertConfirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.PersonaDetails.deauthorizePersonaAlertCancel)
			}
		} message: {
			TextState(L10n.PersonaDetails.deauthorizePersonaAlertMessage)
		}
	}
}

import FeaturePrelude
import ProfileClient

// MARK: - PersonaDetails
public struct PersonaDetails: Sendable, FeatureReducer {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public typealias Store = StoreOf<Self>

	public init() {}

	// MARK: - State

	public struct State: Sendable, Hashable {
		public let dAppName: String
		public let dAppID: OnNetwork.ConnectedDapp.ID
		public let networkID: NetworkID
		public let persona: OnNetwork.AuthorizedPersonaDetailed

		@PresentationState
		public var confirmForgetAlert: AlertState<ViewAction.ConfirmForgetAlert>? = nil

		public init(
			dAppName: String,
			dAppID: OnNetwork.ConnectedDapp.ID,
			networkID: NetworkID,
			persona: OnNetwork.AuthorizedPersonaDetailed
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
		case disconnectPersonaTapped
		case confirmForgetAlert(PresentationAction<AlertState<ConfirmForgetAlert>, ConfirmForgetAlert>)

		public enum ConfirmForgetAlert: Sendable, Equatable {
			case confirmTapped
			case cancelTapped
		}
	}

	public enum DelegateAction: Sendable, Equatable {
		case personaDisconnected
	}

	// MARK: - Reducer

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.presentationDestination(\.$confirmForgetAlert, action: /Action.view .. ViewAction.confirmForgetAlert) {
				EmptyReducer()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .editPersonaTapped:
			return .none

		case let .accountTapped(address):
			return .none

		case .editAccountSharingTapped:
			return .none

		case .disconnectPersonaTapped:
			state.confirmForgetAlert = .confirmForget
			return .none

		case .confirmForgetAlert(.presented(.confirmTapped)):
			let (personaID, dAppID, networkID) = (state.persona.id, state.dAppID, state.networkID)
			return .run { send in
				try await profileClient.disconnectPersonaFromDapp(personaID, dAppID, networkID)
				await send(.delegate(.personaDisconnected))
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
			TextState(L10n.PersonaDetails.disconnectPersonaAlertTitle)
		} actions: {
			ButtonState(role: .destructive, action: .confirmTapped) {
				TextState(L10n.PersonaDetails.disconnectPersonaAlertConfirm)
			}
			ButtonState(role: .cancel, action: .cancelTapped) {
				TextState(L10n.PersonaDetails.disconnectPersonaAlertCancel)
			}
		} message: {
			TextState(L10n.PersonaDetails.disconnectPersonaAlertMessage)
		}
	}
}

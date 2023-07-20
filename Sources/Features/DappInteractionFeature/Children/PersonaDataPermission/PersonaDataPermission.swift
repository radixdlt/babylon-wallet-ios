import EditPersonaFeature
import FeaturePrelude
import PersonasClient

// MARK: - PersonaDataPermission
struct PersonaDataPermission: Sendable, FeatureReducer {
	typealias Request = P2P.Dapp.Request.PersonaDataRequestItem
	typealias Response = P2P.Dapp.Response.WalletInteractionSuccessResponse.PersonaDataRequestResponseItem

	struct State: Sendable, Hashable {
		let dappMetadata: DappMetadata
		let personaID: Profile.Network.Persona.ID
		var persona: PersonaDataPermissionBox.State?
		let requested: Request

		@PresentationState
		var destination: Destinations.State?

		init(
			dappMetadata: DappMetadata,
			personaID: Profile.Network.Persona.ID,
			requested: Request
		) {
			self.dappMetadata = dappMetadata
			self.personaID = personaID
			self.requested = requested
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case continueButtonTapped(Response)
	}

	enum InternalAction: Sendable, Equatable {
		case personasLoaded(IdentifiedArrayOf<Profile.Network.Persona>)
	}

	enum ChildAction: Sendable, Equatable {
		case persona(PersonaDataPermissionBox.Action)
		case destination(PresentationAction<Destinations.Action>)
	}

	enum DelegateAction: Sendable, Equatable {
		case personaUpdated(Profile.Network.Persona)
		case continueButtonTapped(Response)
	}

	struct Destinations: Sendable, ReducerProtocol {
		enum State: Sendable, Hashable {
			case editPersona(EditPersona.State)
		}

		enum Action: Sendable, Equatable {
			case editPersona(EditPersona.Action)
		}

		var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.editPersona, action: /Action.editPersona) {
				EditPersona()
			}
		}
	}

	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.persona, action: /Action.child .. ChildAction.persona) {
				PersonaDataPermissionBox()
			}
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destinations()
			}
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .task:
			return .run { send in
				for try await personas in await personasClient.personas() {
					guard !Task.isCancelled else {
						return
					}
					await send(.internal(.personasLoaded(personas)))
				}
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

		case let .continueButtonTapped(response):
			return .send(.delegate(.continueButtonTapped(response)))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case let .personasLoaded(personas):
			if let persona = personas[id: state.personaID] {
				state.persona = .init(persona: persona, requested: state.requested)
			}
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .persona(.delegate(.edit)):
			if let persona = state.persona {
//				state.destination = .editPersona(.init(
//					mode: .dapp(requiredFieldIDs: state.requiredFieldIDs),
//					persona: persona.persona
//				))
			}
			return .none

		case let .destination(.presented(.editPersona(.delegate(.personaSaved(persona))))):
			return .send(.delegate(.personaUpdated(persona)))

		default:
			return .none
		}
	}
}

extension PersonaDataPermission.Response {
	public init(_ personaData: PersonaData) {
		self.init(
			name: personaData.name?.value,
			dateOfBirth: personaData.dateOfBirth?.value,
			companyName: personaData.companyName?.value,
			emailAddresses: personaData.emailAddresses.values,
			phoneNumbers: personaData.phoneNumbers.values,
			urls: personaData.urls.values,
			postalAddresses: personaData.postalAddresses.values,
			creditCards: personaData.creditCards.values
		)
	}

	public typealias Result = Swift.Result<Self, RequestError>

	public struct RequestError: Error, Hashable {
		public let issues: [PersonaData.Entry.Kind: P2P.Dapp.Request.Issue]
	}
}

extension PersonaData.CollectionOfIdentifiedEntries {
	public var values: OrderedSet<Value>? {
		try? .init(validating: collection.elements.map(\.value))
	}
}

extension PersonaDataPermission.Response.Result {
	init(request: PersonaDataPermission.Request, personaData: PersonaData) {
		let issues = personaData.requestIssues(request)
		guard issues.isEmpty else {
			self = .failure(.init(issues: issues))
			return
		}
		self = .success(.init(personaData))
	}
}

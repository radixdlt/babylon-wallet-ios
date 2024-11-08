import ComposableArchitecture
import SwiftUI

// MARK: - CreatePersonaCoordinator
struct CreatePersonaCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = .init()
		var name: NonEmptyString?
		var fields: PersonaData?

		@PresentationState
		var destination: Destination.State? = nil

		let config: CreatePersonaConfig

		init(
			root: Path.State? = nil,
			config: CreatePersonaConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				if config.personaPrimacy.isFirstEver {
					self.root = .step0_introduction
				} else {
					self.root = .step1_createPersona(.init(mode: .create))
				}
			}
		}

		var shouldDisplayNavBar: Bool {
			switch path.last {
			case .step0_introduction, .step1_createPersona:
				true
			case .step2_completion:
				false
			case .none:
				true
			}
		}
	}

	struct Path: Sendable, Reducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case step0_introduction
			case step1_createPersona(EditPersona.State)
			case step2_completion(NewPersonaCompletion.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case step0_introduction
			case step1_createPersona(EditPersona.Action)
			case step2_completion(NewPersonaCompletion.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.step1_createPersona, action: \.step1_createPersona) {
				EditPersona()
			}
			Scope(state: \.step2_completion, action: \.step2_completion) {
				NewPersonaCompletion()
			}
		}
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.State)
		}

		@CasePathable
		enum Action: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.derivePublicKey, action: \.derivePublicKey) {
				DerivePublicKeys()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case introductionContinueButtonTapped
	}

	enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed(Persona)
	}

	enum InternalAction: Sendable, Equatable {
		case derivePublicKey
		case createPersonaResult(TaskResult<Persona>)
		case handleFailure
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination
}

extension CreatePersonaCoordinator {
	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismissed))
				await dismiss()
			}

		case .introductionContinueButtonTapped:
			state.path.append(.step1_createPersona(.init(mode: .create)))
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case
			let .root(.step1_createPersona(.delegate(.personaInfoSet(name, fields)))),
			let .path(.element(_, action: .step1_createPersona(.delegate(.personaInfoSet(name, fields))))):
			state.name = name
			state.fields = fields

			return .send(.internal(.derivePublicKey))

		case let .path(.element(_, action: .step2_completion(.delegate(.completed(persona))))):
			return .run { send in
				await send(.delegate(.completed(persona)))
				await dismiss()
			}

		default:
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case .derivePublicKey:
			state.destination = .derivePublicKey(
				.init(
					derivationPathOption: .next(
						networkOption: .useCurrent,
						entityKind: .persona,
						curve: .curve25519,
						scheme: .cap26
					),
					factorSourceOption: .device,
					purpose: .createNewEntity(kind: .persona)
				)
			)
			return .none

		case let .createPersonaResult(.success(persona)):
			state.destination = nil
			state.path.append(.step2_completion(.init(
				persona: persona,
				config: state.config
			)))
			return .none

		case let .createPersonaResult(.failure(error)):
			errorQueue.schedule(error)
			state.destination = nil
			return .none

		case .handleFailure:
			state.destination = nil
			return .none
		}
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKey(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, networkID))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create persona expected one single key, got: \(hdKeys.count)")
				return .send(.internal(.handleFailure))
			}
			guard let name = state.name, let personaData = state.fields else {
				fatalError("Derived keys without persona name or extra fields set")
			}
			return .run { send in
				let factorSourceIDFromHash = try factorSourceID.extract(as: FactorSourceIDFromHash.self)
				let persona = Persona(
					networkID: networkID,
					factorInstance: HierarchicalDeterministicFactorInstance(
						factorSourceId: factorSourceIDFromHash,
						publicKey: hdKey
					),
					displayName: DisplayName(nonEmpty: name),
					extraProperties: .init(personaData: personaData)
				)

				await send(.internal(.createPersonaResult(
					TaskResult {
						try await personasClient.saveVirtualPersona(persona)
						return persona
					}
				)))
			} catch: { error, send in
				loggerGlobal.error("Failed to create persona, error: \(error)")
				await send(.internal(.handleFailure))
			}

		case .derivePublicKey(.delegate(.failedToDerivePublicKey)):
			return .send(.internal(.handleFailure))

		default:
			return .none
		}
	}
}

import ComposableArchitecture
import SwiftUI

// MARK: - CreatePersonaCoordinator
public struct CreatePersonaCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = .init()
		var name: NonEmptyString?
		var fields: PersonaData?

		@PresentationState
		var destination: Destination.State? = nil

		public let config: CreatePersonaConfig

		public init(
			root: Path.State? = nil,
			config: CreatePersonaConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				if config.personaPrimacy.isFirstEver {
					self.root = .step0_introduction(.init())
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

	public struct Path: Sendable, Reducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case step0_introduction(IntroductionToPersonas.State)
			case step1_createPersona(EditPersona.State)
			case step2_completion(NewPersonaCompletion.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case step0_introduction(IntroductionToPersonas.Action)
			case step1_createPersona(EditPersona.Action)
			case step2_completion(NewPersonaCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.step0_introduction, action: \.step0_introduction) {
				IntroductionToPersonas()
			}
			Scope(state: \.step1_createPersona, action: \.step1_createPersona) {
				EditPersona()
			}
			Scope(state: \.step2_completion, action: \.step2_completion) {
				NewPersonaCompletion()
			}
		}
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.State)
		}

		@CasePathable
		public enum Action: Sendable, Hashable {
			case derivePublicKey(DerivePublicKeys.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: \.derivePublicKey, action: \.derivePublicKey) {
				DerivePublicKeys()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed(Persona)
	}

	public enum InternalAction: Sendable, Equatable {
		case derivePublicKey
		case createPersonaResult(TaskResult<Persona>)
		case handleFailure
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerOf<Self> {
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
	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .closeButtonTapped:
			.run { send in
				await send(.delegate(.dismissed))
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .root(.step0_introduction(.delegate(.done))):
			state.path.append(.step1_createPersona(.init(mode: .create)))
			return .none

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

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .derivePublicKey(.delegate(.derivedPublicKeys(hdKeys, factorSourceID, networkID))):
			guard let hdKey = hdKeys.first else {
				loggerGlobal.error("Failed to create persona expected one single key, got: \(hdKeys.count)")
				return .send(.internal(.handleFailure))
			}
			guard let name = state.name, let personaData = state.fields else {
				fatalError("Derived public keys without persona name or extra fields set")
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

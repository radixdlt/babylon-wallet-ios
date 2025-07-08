import ComposableArchitecture
import SwiftUI

// MARK: - CreatePersonaCoordinator
struct CreatePersonaCoordinator: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		var root: Path.State?
		var path: StackState<Path.State> = .init()

		let config: CreatePersonaConfig
		var name: NonEmptyString!
		var personaData: PersonaData!

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
			case .step0_introduction, .step1_createPersona, .selectFactorSource:
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
			case selectFactorSource(SelectFactorSource.State)
			case step2_completion(NewPersonaCompletion.State)
		}

		@CasePathable
		enum Action: Sendable, Equatable {
			case step0_introduction
			case step1_createPersona(EditPersona.Action)
			case selectFactorSource(SelectFactorSource.Action)
			case step2_completion(NewPersonaCompletion.Action)
		}

		var body: some ReducerOf<Self> {
			Scope(state: \.step1_createPersona, action: \.step1_createPersona) {
				EditPersona()
			}
			Scope(state: \.selectFactorSource, action: \.selectFactorSource) {
				SelectFactorSource()
			}
			Scope(state: \.step2_completion, action: \.step2_completion) {
				NewPersonaCompletion()
			}
		}
	}

	enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
		case introductionContinueButtonTapped
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackActionOf<Path>)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed(Persona)
	}

	enum InternalAction: Sendable, Equatable {
		case handlePersonaCreated(Persona)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.personasClient) var personasClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: \.child.root) {
				Path()
			}
			.forEach(\.path, action: \.child.path) {
				Path()
			}
	}
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
			let .root(.step1_createPersona(.delegate(.personaInfoSet(name, personaData)))),
			let .path(.element(_, action: .step1_createPersona(.delegate(.personaInfoSet(name, personaData))))):
			state.name = name
			state.personaData = personaData

			state.path.append(.selectFactorSource(.init(kinds: [.device, .ledgerHqHardwareWallet, .arculusCard])))
			return .none

		case let .path(.element(_, action: .selectFactorSource(.delegate(.selectedFactorSource(fs))))):
			let name = state.name
			let personaData = state.personaData
			return .run { send in
				let persona = try await SargonOS.shared.createPersona(
					factorSource: fs,
					name: .init(nonEmpty: name!),
					personaData: personaData
				)
				await send(.internal(.handlePersonaCreated(persona)))
			} catch: { error, _ in
				errorQueue.schedule(error)
			}

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
		case let .handlePersonaCreated(persona):
			state.path.append(.step2_completion(.init(
				persona: persona,
				config: state.config
			)))
			return .none
		}
	}

	private func createPersona(name: NonEmptyString, personaData: PersonaData) -> Effect<Action> {
		.run { _ in
			fatalError("TODO")
//			let persona = try await SargonOS.shared.createPersonaWithBDFS(name: .init(nonEmpty: name), personaData: personaData)
//			await send(.internal(.handlePersonaCreated(persona)))
		} catch: { error, _ in
			errorQueue.schedule(error)
		}
	}
}

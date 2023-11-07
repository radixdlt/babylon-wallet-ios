import ComposableArchitecture
import SwiftUI

// MARK: - CreatePersonaCoordinator
public struct CreatePersonaCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Destination.State?
		var path: StackState<Destination.State> = .init()

		public let config: CreatePersonaConfig

		public init(
			root: Destination.State? = nil,
			config: CreatePersonaConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				if config.personaPrimacy.isFirstEver {
					self.root = .step0_introduction(.init())
				} else {
					self.root = .step1_newPersonaInfo(.init(config: config))
				}
			}
		}

		var shouldDisplayNavBar: Bool {
			if let last = path.last {
				if case .step3_completion = last {
					return false
				} else if case .step2_creationOfPersona = last {
					return false
				} else {
					return true
				}
			}
			return true
		}
	}

	public struct Destination: Sendable, Reducer {
		public enum State: Sendable, Hashable {
			case step0_introduction(IntroductionToPersonas.State)
			case step1_newPersonaInfo(NewPersonaInfo.State)
			case step2_creationOfPersona(CreationOfPersona.State)
			case step3_completion(NewPersonaCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case step0_introduction(IntroductionToPersonas.Action)
			case step1_newPersonaInfo(NewPersonaInfo.Action)
			case step2_creationOfPersona(CreationOfPersona.Action)
			case step3_completion(NewPersonaCompletion.Action)
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.step0_introduction, action: /Action.step0_introduction) {
				IntroductionToPersonas()
			}
			Scope(state: /State.step1_newPersonaInfo, action: /Action.step1_newPersonaInfo) {
				NewPersonaInfo()
			}
			Scope(state: /State.step2_creationOfPersona, action: /Action.step2_creationOfPersona) {
				CreationOfPersona()
			}
			Scope(state: /State.step3_completion, action: /Action.step3_completion) {
				NewPersonaCompletion()
			}
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case closeButtonTapped
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Destination.Action)
		case path(StackActionOf<Destination>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destination()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destination()
			}
	}
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
			state.path.append(.step1_newPersonaInfo(.init(config: state.config)))
			return .none

		case
			let .root(.step1_newPersonaInfo(.delegate(.proceed(name, fields)))),
			let .path(.element(_, action: .step1_newPersonaInfo(.delegate(.proceed(name, fields))))):

			// FIXME: use "fields"
			state.path.append(.step2_creationOfPersona(.init(
				name: name
			)))
			return .none

		case let .path(.element(_, action: .step2_creationOfPersona(.delegate(.createdPersona(persona))))):
			state.path.append(.step3_completion(.init(
				persona: persona,
				config: state.config
			)))
			return .none

		case .path(.element(_, action: .step2_creationOfPersona(.delegate(.createPersonaFailed)))):
			state.path.removeLast()
			return .none

		case .path(.element(_, action: .step3_completion(.delegate(.completed)))):
			return .run { send in
				await send(.delegate(.completed))
				await dismiss()
			}

		default:
			return .none
		}
	}
}

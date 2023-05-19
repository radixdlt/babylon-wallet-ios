import Cryptography
import DerivePublicKeyFeature
import FactorSourcesClient
import FeaturePrelude

// MARK: - CreatePersonaCoordinator
public struct CreatePersonaCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		var root: Destinations.State?
		var path: StackState<Destinations.State> = []

		public let config: CreatePersonaConfig

		public init(
			root: Destinations.State? = nil,
			config: CreatePersonaConfig
		) {
			self.config = config
			if let root {
				self.root = root
			} else {
				if config.isFirstPersona.isFirstEver {
					self.root = .step0_introduction(.init())
				} else {
					self.root = .step1_infoOfNewPersona(.init(config: config))
				}
			}
		}

		var shouldDisplayNavBar: Bool {
			if let last = path.last {
				if case .step3_completion = last {
					return false
				} else {
					return true
				}
			}
			return true
		}
	}

	public struct Destinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case step0_introduction(IntroductionToPersonas.State)
			case step1_infoOfNewPersona(InfoOfNewPersona.State)
			case step2_creationOfPersona(CreationOfPersona.State)
			case step3_completion(NewPersonaCompletion.State)
		}

		public enum Action: Sendable, Equatable {
			case step0_introduction(IntroductionToPersonas.Action)
			case step1_infoOfNewPersona(InfoOfNewPersona.Action)
			case step2_creationOfPersona(CreationOfPersona.Action)
			case step3_completion(NewPersonaCompletion.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.step0_introduction, action: /Action.step0_introduction) {
				IntroductionToPersonas()
			}
			Scope(state: /State.step1_infoOfNewPersona, action: /Action.step1_infoOfNewPersona) {
				InfoOfNewPersona()
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
		case root(Destinations.Action)
		case path(StackAction<Destinations.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismissed
		case completed
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.dismiss) var dismiss

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Destinations()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Destinations()
			}
	}
}

extension CreatePersonaCoordinator {
	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismissed))
				await dismiss()
			}
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .root(.step0_introduction(.delegate(.done))):
			state.path.append(.step1_infoOfNewPersona(.init(config: state.config)))
			return .none

		case
			let .root(.step1_infoOfNewPersona(.delegate(.proceed(name, fields)))),
			let .path(.element(_, action: .step1_infoOfNewPersona(.delegate(.proceed(name, fields))))):

			state.path.append(.step2_creationOfPersona(.init(
				name: name,
				fields: fields
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

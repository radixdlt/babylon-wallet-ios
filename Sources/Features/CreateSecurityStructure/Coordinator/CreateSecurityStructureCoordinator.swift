import AddTrustedContactFactorSourceFeature
import AnswerSecurityQuestionsFeature
import FactorSourcesClient
import FeaturePrelude
import Profile

// MARK: - CreateSecurityStructureCoordinator
public struct CreateSecurityStructureCoordinator: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		@PresentationState
		public var modalDestinations: ModalDestinations.State?

		var root: Path.State?
		var path: StackState<Path.State> = []

		public init() {
			root = .start(.init())
		}
	}

	public struct Path: Sendable, Hashable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case start(CreateSecurityStructureStart.State)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.State)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.State)
			case nameNewStructure(NameNewSecurityStructure.State)

			var simpleSetupFlow: SimpleCreateSecurityStructureFlow.State? {
				guard case let .simpleSetupFlow(simpleSetupFlow) = self else { return nil }
				return simpleSetupFlow
			}
		}

		public enum Action: Sendable, Equatable {
			case start(CreateSecurityStructureStart.Action)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.Action)
			case nameNewStructure(NameNewSecurityStructure.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.start, action: /Action.start) {
				CreateSecurityStructureStart()
			}
			Scope(state: /State.simpleSetupFlow, action: /Action.simpleSetupFlow) {
				SimpleCreateSecurityStructureFlow()
			}
			Scope(state: /State.advancedSetupFlow, action: /Action.advancedSetupFlow) {
				AdvancedCreateSecurityStructureFlow()
			}
			Scope(state: /State.nameNewStructure, action: /Action.nameNewStructure) {
				NameNewSecurityStructure()
			}
		}
	}

	public enum ChildAction: Sendable, Equatable {
		case root(Path.Action)
		case path(StackAction<Path.Action>)

		case modalDestinations(PresentationAction<ModalDestinations.Action>)
	}

	public struct ModalDestinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case simpleNewPhoneConfirmer(AnswerSecurityQuestionsCoordinator.State)
			case simpleLostPhoneHelper(AddTrustedContactFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case simpleNewPhoneConfirmer(AnswerSecurityQuestionsCoordinator.Action)
			case simpleLostPhoneHelper(AddTrustedContactFactorSource.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.simpleNewPhoneConfirmer, action: /Action.simpleNewPhoneConfirmer) {
				AnswerSecurityQuestionsCoordinator()
			}
			Scope(state: /State.simpleLostPhoneHelper, action: /Action.simpleLostPhoneHelper) {
				AddTrustedContactFactorSource()
			}
		}
	}

	public enum DelegateAction: Sendable, Hashable {
		case done(TaskResult<SecurityStructureConfiguration>)
	}

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient
	public init() {}

	public var body: some ReducerProtocolOf<CreateSecurityStructureCoordinator> {
		Reduce(core)
			.ifLet(\.root, action: /Action.child .. ChildAction.root) {
				Path()
			}
			.forEach(\.path, action: /Action.child .. ChildAction.path) {
				Path()
			}
			.ifLet(\.$modalDestinations, action: /Action.child .. ChildAction.modalDestinations) {
				ModalDestinations()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case .root(.start(.delegate(.simpleFlow))):
			state.path.append(.simpleSetupFlow(.init()))
			return .none
		case .root(.start(.delegate(.advancedFlow))):
			state.path.append(.advancedSetupFlow(.init()))
			return .none

		case .path(.element(_, action: .simpleSetupFlow(.delegate(.selectNewPhoneConfirmer)))):
			state.modalDestinations = .simpleNewPhoneConfirmer(.init(purpose: .encrypt))
			return .none

		case .path(.element(_, action: .simpleSetupFlow(.delegate(.selectLostPhoneHelper)))):
			state.modalDestinations = .simpleLostPhoneHelper(.init())
			return .none

		case let .path(.element(_, action: .simpleSetupFlow(.delegate(.createSecurityStructure(simpleFlowResult))))):

			switch simpleFlowResult {
			case let .success(simple):
				let config = SecurityStructureConfiguration.Configuration(from: simple)
				state.path.append(.nameNewStructure(.init(configuration: config)))
			case let .failure(error):
				loggerGlobal.error("Failed to create simple security structure, error: \(error)")
				errorQueue.schedule(error)
			}

			return .none

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.success(lostPhoneHelper)))))):
			// FIXME: uh.. this is terrible... hmm change to tree based navigation?
			guard
				let simpleSetupFlowIndex = state.path.firstIndex(where: { $0.simpleSetupFlow != nil }),
				var simpleSetupFlow = state.path[simpleSetupFlowIndex].simpleSetupFlow
			else {
				assertionFailure("Unexpectedly were in wrong state..?")
				return .none
			}
			simpleSetupFlow.lostPhoneHelper = lostPhoneHelper
			state.path[simpleSetupFlowIndex] = .simpleSetupFlow(simpleSetupFlow)
			state.modalDestinations = nil
			return .none

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to create lost phone helper, error: \(error)")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.encrypted(newPhoneConfirmer))))))):
			// FIXME: uh.. this is terrible... hmm change to tree based navigation?
			guard
				let simpleSetupFlowIndex = state.path.firstIndex(where: { $0.simpleSetupFlow != nil }),
				var simpleSetupFlow = state.path[simpleSetupFlowIndex].simpleSetupFlow
			else {
				assertionFailure("Unexpectedly were in wrong state..?")
				return .none
			}
			simpleSetupFlow.newPhoneConfirmer = newPhoneConfirmer
			state.path[simpleSetupFlowIndex] = .simpleSetupFlow(simpleSetupFlow)
			state.modalDestinations = nil
			return .none

		case .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.decrypted)))))):
			state.modalDestinations = nil
			assertionFailure("Expected to encrypt, not decrypt.")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to create new phone confirmer, error: \(error)")
			return .none

		case let .path(.element(_, action: .nameNewStructure(.delegate(.securityStructureCreationResult(result))))):
			return .send(.delegate(.done(result)))

		default: return .none
		}
	}
}

extension SecurityStructureConfiguration.Configuration {
	init(from simple: SimpleUnnamedSecurityStructureConfig) {
		self.init(
			primaryRole: .single(simple.singlePrimaryFactor),
			recoveryRole: .single(simple.singleRecoveryFactor),
			confirmationRole: .single(simple.singleConfirmationFactor)
		)
	}
}

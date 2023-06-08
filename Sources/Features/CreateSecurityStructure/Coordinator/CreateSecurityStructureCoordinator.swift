import AddTrustedContactFactorSourceFeature
import AnswerSecurityQuestionsFeature
import FactorSourcesClient
import FeaturePrelude
import Profile

extension SecurityQuestionsFactorSource {
	public static let defaultQuestions: NonEmpty<OrderedSet<SecurityQuestion>> = {
		.init(
			rawValue: .init(
				uncheckedUniqueElements:
				[
					"Name of Radix DLT's Founder?",
					"Name of Radix DLT's CEO?",
					"Name of Radix DLT's CTO?",
					"Common first name amongst Radix DLT employees from Sweden?",
				].enumerated().map {
					SecurityQuestion(
						id: .init(UInt($0.offset)),
						question: .init(rawValue: $0.element)!
					)
				}
			))!
	}()
}

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

			var simpleSetupFlow: SimpleCreateSecurityStructureFlow.State? {
				guard case let .simpleSetupFlow(simpleSetupFlow) = self else { return nil }
				return simpleSetupFlow
			}
		}

		public enum Action: Sendable, Equatable {
			case start(CreateSecurityStructureStart.Action)
			case simpleSetupFlow(SimpleCreateSecurityStructureFlow.Action)
			case advancedSetupFlow(AdvancedCreateSecurityStructureFlow.Action)
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
			state.modalDestinations = .simpleNewPhoneConfirmer(.init(purpose: .encrypt(SecurityQuestionsFactorSource.defaultQuestions)))
			return .none

		case .path(.element(_, action: .simpleSetupFlow(.delegate(.selectLostPhoneHelper)))):
			state.modalDestinations = .simpleLostPhoneHelper(.init())
			return .none

		case let .path(.element(_, action: .simpleSetupFlow(.delegate(.createSecurityStructure(simpleFactorConfig))))):
			return .task {
				let taskResult = await TaskResult {
					let primary = try await factorSourcesClient
						.getFactorSources(matching: {
							$0.kind == .device && !$0.supportsOlympia
						}).first!

					return SecurityStructureConfiguration(
						label: "Unnamed",
						configuration: .init(
							primaryRole: .single(primary),
							recoveryRole: .single(simpleFactorConfig.lostPhoneHelper.embed()),
							confirmationRole: .single(simpleFactorConfig.newPhoneConfirmer.embed())
						)
					)
				}
				return .delegate(.done(taskResult))
			}

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.success(lostPhoneHelper)))))):
			// FIXME: uh.. this is terrible... hmm change to tree based navigation?
			guard
				let simpleSetupFlowIndex = state.path.firstIndex(where: { $0.simpleSetupFlow != nil }),
				var simpleSetupFlow = state.path[simpleSetupFlowIndex].simpleSetupFlow
			else {
				assertionFailure("Unexpectly where in wrong state..?")
				return .none
			}
			simpleSetupFlow.lostPhoneHelper = lostPhoneHelper
			state.path[simpleSetupFlowIndex] = .simpleSetupFlow(simpleSetupFlow)
			state.modalDestinations = nil
			return .none

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			loggerGlobal.error("Failed to create lost phone helper, error: \(error)")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.encrypted(newPhoneConfirmer))))))):
			// FIXME: uh.. this is terrible... hmm change to tree based navigation?
			guard
				let simpleSetupFlowIndex = state.path.firstIndex(where: { $0.simpleSetupFlow != nil }),
				var simpleSetupFlow = state.path[simpleSetupFlowIndex].simpleSetupFlow
			else {
				assertionFailure("Unexpectly where in wrong state..?")
				return .none
			}
			simpleSetupFlow.newPhoneConfirmer = newPhoneConfirmer
			state.path[simpleSetupFlowIndex] = .simpleSetupFlow(simpleSetupFlow)
			state.modalDestinations = nil
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.decrypted)))))):
			state.modalDestinations = nil
			assertionFailure("Expected to encrypt, not decrypt.")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			loggerGlobal.error("Failed to create new phone confirmer, error: \(error)")
			return .none

		default: return .none
		}
	}
}

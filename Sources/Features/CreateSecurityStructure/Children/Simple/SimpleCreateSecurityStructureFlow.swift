import AddTrustedContactFactorSourceFeature
import AnswerSecurityQuestionsFeature
import FactorSourcesClient
import FeaturePrelude

// MARK: - SimpleUnnamedSecurityStructureConfig
public struct SimpleUnnamedSecurityStructureConfig: Sendable, Hashable {
	let singlePrimaryFactor: DeviceFactorSource
	let singleRecoveryFactor: TrustedContactFactorSource
	let singleConfirmationFactor: SecurityQuestionsFactorSource
}

// MARK: - SimpleCreateSecurityStructureFlow
public struct SimpleCreateSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		/// Confirmation role
		public var newPhoneConfirmer: SecurityQuestionsFactorSource?

		/// Recovery role
		public var lostPhoneHelper: TrustedContactFactorSource?

		@PresentationState
		public var modalDestinations: ModalDestinations.State?

		public init(
			newPhoneConfirmer: SecurityQuestionsFactorSource? = nil,
			lostPhoneHelper: TrustedContactFactorSource? = nil
		) {
			self.newPhoneConfirmer = newPhoneConfirmer
			self.lostPhoneHelper = lostPhoneHelper
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case selectNewPhoneConfirmer
		case selectLostPhoneHelper
		case finishSelectingFactors(RecoveryAndConfirmationFactors)
	}

	public enum DelegateAction: Sendable, Equatable {
		case createSecurityStructure(TaskResult<SimpleUnnamedSecurityStructureConfig>)
	}

	public enum ChildAction: Sendable, Equatable {
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

	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$modalDestinations, action: /Action.child .. ChildAction.modalDestinations) {
				ModalDestinations()
			}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.success(lostPhoneHelper)))))):
			state.lostPhoneHelper = lostPhoneHelper
			state.modalDestinations = nil
			return .none

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to create lost phone helper, error: \(error)")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.encrypted(newPhoneConfirmer))))))):
			state.newPhoneConfirmer = newPhoneConfirmer
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

		default: return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectNewPhoneConfirmer:
			state.modalDestinations = .simpleNewPhoneConfirmer(.init(purpose: .encrypt))
			return .none

		case .selectLostPhoneHelper:
			state.modalDestinations = .simpleLostPhoneHelper(.init())
			return .none
		case let .finishSelectingFactors(simpleFactorConfig):
			return .task {
				let taskResult = await TaskResult {
					let primary = try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self).filter {
						!$0.supportsOlympia
					}.first!

					let simpleUnnamed = SimpleUnnamedSecurityStructureConfig(
						singlePrimaryFactor: primary,
						singleRecoveryFactor: simpleFactorConfig.singleRecoveryFactor,
						singleConfirmationFactor: simpleFactorConfig.singleConfirmationFactor
					)

					return simpleUnnamed
				}
				return .delegate(.createSecurityStructure(taskResult))
			}
		}
	}
}

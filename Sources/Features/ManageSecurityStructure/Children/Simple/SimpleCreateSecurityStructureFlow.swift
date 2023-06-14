import AnswerSecurityQuestionsFeature
import FactorSourcesClient
import FeaturePrelude
import ManageTrustedContactFactorSourceFeature

// MARK: - SimpleUnnamedSecurityStructureConfig
public struct SimpleUnnamedSecurityStructureConfig: Sendable, Hashable {
	let singlePrimaryFactor: DeviceFactorSource
	let singleRecoveryFactor: TrustedContactFactorSource
	let singleConfirmationFactor: SecurityQuestionsFactorSource
}

// MARK: - ConfirmerOfNewPhone
public struct ConfirmerOfNewPhone: Sendable, Hashable {
	public let factorSource: SecurityQuestionsFactorSource
	public let answersToQuestions: NonEmpty<OrderedSet<AbstractAnswerToSecurityQuestion<NonEmptyString>>>
}

// MARK: - SimpleManageSecurityStructureFlow
public struct SimpleManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfiguration)
			case new(New)

			public struct New: Sendable, Hashable {
				public var lostPhoneHelper: TrustedContactFactorSource?
				public var confirmerOfNewPhone: ConfirmerOfNewPhone?

				public init(
					lostPhoneHelper: TrustedContactFactorSource? = nil,
					confirmerOfNewPhone: ConfirmerOfNewPhone? = nil
				) {
					self.lostPhoneHelper = lostPhoneHelper
					self.confirmerOfNewPhone = confirmerOfNewPhone
				}
			}
		}

		public var mode: Mode

		@PresentationState
		public var modalDestinations: ModalDestinations.State?

		public init(
			mode: Mode = .new(.init())
		) {
			self.mode = mode
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case confirmerOfNewPhoneButtonTapped
		case lostPhoneHelperButtonTapped
		case finished(RecoveryAndConfirmationFactors)
	}

	public enum DelegateAction: Sendable, Equatable {
		public enum Product: Sendable, Equatable {
			case updating(structure: SecurityStructureConfiguration)
			case creatingNew(config: SecurityStructureConfiguration.Configuration)
		}

		case updatedOrCreatedSecurityStructure(TaskResult<Product>)
	}

	public enum ChildAction: Sendable, Equatable {
		case modalDestinations(PresentationAction<ModalDestinations.Action>)
	}

	public struct ModalDestinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case simpleNewPhoneConfirmer(AnswerSecurityQuestionsCoordinator.State)
			case simpleLostPhoneHelper(ManageTrustedContactFactorSource.State)
		}

		public enum Action: Sendable, Equatable {
			case simpleNewPhoneConfirmer(AnswerSecurityQuestionsCoordinator.Action)
			case simpleLostPhoneHelper(ManageTrustedContactFactorSource.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.simpleNewPhoneConfirmer, action: /Action.simpleNewPhoneConfirmer) {
				AnswerSecurityQuestionsCoordinator()
			}
			Scope(state: /State.simpleLostPhoneHelper, action: /Action.simpleLostPhoneHelper) {
				ManageTrustedContactFactorSource()
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
			switch state.mode {
			case var .new(new):
				new.lostPhoneHelper = lostPhoneHelper
				state.mode = .new(new)
			case var .existing(existing):
				// FIXME: Error handling
				try! existing.configuration.recoveryRole.changeFactorSource(to: lostPhoneHelper)
				state.mode = .existing(existing)
			}
			state.modalDestinations = nil
			return .none

		case let .modalDestinations(.presented(.simpleLostPhoneHelper(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to create lost phone helper, error: \(error)")
			return .none

		case let .modalDestinations(.presented(.simpleNewPhoneConfirmer(.delegate(.done(.success(.encrypted(factorSource, answersToQuestions))))))):
			switch state.mode {
			case var .new(new):
				new.confirmerOfNewPhone = .init(factorSource: factorSource, answersToQuestions: answersToQuestions)
				state.mode = .new(new)
			case var .existing(existing):
				// FIXME: Error handling
				try! existing.configuration.confirmationRole.changeFactorSource(to: factorSource)
				state.mode = .existing(existing)
			}
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
		case .confirmerOfNewPhoneButtonTapped:
			let purpose: AnswerSecurityQuestionsCoordinator.State.Purpose = {
				switch state.mode {
				case let .existing(structure):
//					guard structure.isSimple, let factorSource = structure.configuration.confirmationRole.thresholdFactors[0].extract(SecurityQuestionsFactorSource.self) else {
//						return .encrypt()
//					}
//					return .editing(factorSource: factorSource)
					return .encrypt()
				case let .new(new):
					if let confirmerOfNewPhone = new.confirmerOfNewPhone {
						return .editing(editingAnswersToQuestions: confirmerOfNewPhone.answersToQuestions)
					} else {
						return .encrypt()
					}
				}
			}()
			state.modalDestinations = .simpleNewPhoneConfirmer(.init(purpose: purpose))
			return .none

		case .lostPhoneHelperButtonTapped:
			let mode: ManageTrustedContactFactorSource.State.Mode = {
				switch state.mode {
				case let .existing(structure):
					guard structure.isSimple, let factorSource = structure.configuration.recoveryRole.thresholdFactors[0].extract(TrustedContactFactorSource.self) else {
						return .new
					}
					return .existing(factorSource)
				case let .new(new):
					if let unsavedTrustedContact = new.lostPhoneHelper {
						return .existing(unsavedTrustedContact)
					} else {
						return .new
					}
				}
			}()
			state.modalDestinations = .simpleLostPhoneHelper(.init(mode: mode))
			return .none

		case let .finished(simpleFactorConfig):

			switch state.mode {
			case let .new(new):
				precondition(new.lostPhoneHelper == simpleFactorConfig.singleRecoveryFactor)
				precondition(new.confirmerOfNewPhone?.factorSource == simpleFactorConfig.singleConfirmationFactor)

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
						let config = SecurityStructureConfiguration.Configuration(from: simpleUnnamed)
						return Self.DelegateAction.Product.creatingNew(config: config)
					}
					return .delegate(.updatedOrCreatedSecurityStructure(taskResult))
				}

			case let .existing(structureToUpdate):
				return .send(.delegate(.updatedOrCreatedSecurityStructure(.success(.updating(structure: structureToUpdate)))))
			}
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

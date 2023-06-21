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

public typealias ListConfirmerOfPhone = FactorSourcesOfKindList<SecurityQuestionsFactorSource>
public typealias ListLostPhoneHelper = FactorSourcesOfKindList<TrustedContactFactorSource>

// MARK: - SimpleManageSecurityStructureFlow
public struct SimpleManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfiguration)
			case new(New)

			public struct New: Sendable, Hashable {
				public var lostPhoneHelper: TrustedContactFactorSource?
				public var confirmerOfNewPhone: SecurityQuestionsFactorSource?

				public init(
					lostPhoneHelper: TrustedContactFactorSource? = nil,
					confirmerOfNewPhone: SecurityQuestionsFactorSource? = nil
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
			case firstConfirmerOfPhone(AnswerSecurityQuestionsCoordinator.State)
			case listConfirmerOfPhone(ListConfirmerOfPhone.State)

			case firstLostPhoneHelper(ManageTrustedContactFactorSource.State)
			case listLostPhoneHelper(ListLostPhoneHelper.State)
		}

		public enum Action: Sendable, Equatable {
			case firstConfirmerOfPhone(AnswerSecurityQuestionsCoordinator.Action)
			case listConfirmerOfPhone(ListConfirmerOfPhone.Action)

			case firstLostPhoneHelper(ManageTrustedContactFactorSource.Action)
			case listLostPhoneHelper(ListLostPhoneHelper.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.firstConfirmerOfPhone, action: /Action.firstConfirmerOfPhone) {
				AnswerSecurityQuestionsCoordinator()
			}
			Scope(state: /State.listConfirmerOfPhone, action: /Action.listConfirmerOfPhone) {
				ListConfirmerOfPhone()
			}

			Scope(state: /State.firstLostPhoneHelper, action: /Action.firstLostPhoneHelper) {
				ManageTrustedContactFactorSource()
			}
			Scope(state: /State.listLostPhoneHelper, action: /Action.listLostPhoneHelper) {
				ListLostPhoneHelper()
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

	private func choseConfirmerOfPhone(
		_ factorSource: SecurityQuestionsFactorSource,
		_ state: inout State
	) -> EffectTask<Action> {
		switch state.mode {
		case var .new(new):
			new.confirmerOfNewPhone = factorSource
			state.mode = .new(new)
		case var .existing(existing):
			// FIXME: Error handling
			try! existing.configuration.confirmationRole.changeFactorSource(to: factorSource)
			state.mode = .existing(existing)
		}
		state.modalDestinations = nil
		return .none
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modalDestinations(.presented(.firstLostPhoneHelper(.delegate(.done(lostPhoneHelper))))):
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

		case let .modalDestinations(.presented(.firstConfirmerOfPhone(.delegate(.done(.success(.encrypted(factorSource))))))):
			return choseConfirmerOfPhone(factorSource, &state)

		case .modalDestinations(.presented(.firstConfirmerOfPhone(.delegate(.done(.success(.decrypted)))))):
			state.modalDestinations = nil
			assertionFailure("Expected to encrypt, not decrypt.")
			return .none

		case let .modalDestinations(.presented(.firstConfirmerOfPhone(.delegate(.done(.failure(error)))))):
			state.modalDestinations = nil
			errorQueue.schedule(error)
			loggerGlobal.error("Failed to create new phone confirmer, error: \(error)")
			return .none

		case let .modalDestinations(.presented(.listConfirmerOfPhone(.delegate(.choseFactorSource(savedOrDraftFactorSource))))):

			return choseConfirmerOfPhone(savedOrDraftFactorSource, &state)

		default: return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .confirmerOfNewPhoneButtonTapped:
			switch state.mode {
			case let .existing(structure):
				precondition(structure.isSimple)
				state.modalDestinations = .listConfirmerOfPhone(.init(
					mode: .selection,
					factorSource: structure.securityQuestionsFactorSource
				))
			case .new:
				state.modalDestinations = .firstConfirmerOfPhone(.init(
					purpose: .encrypt
				))
			}
			return .none

		case .lostPhoneHelperButtonTapped:
			let mode: ManageTrustedContactFactorSource.State.Mode = {
				switch state.mode {
				case let .existing(structure):
					guard structure.isSimple, let factorSource = structure.configuration.recoveryRole.thresholdFactors[0].extract(TrustedContactFactorSource.self) else {
						return .new
					}
					return .existing(factorSource, isFactorSourceSavedInProfile: true)
				case let .new(new):
					if let unsavedTrustedContact = new.lostPhoneHelper {
						return .existing(unsavedTrustedContact, isFactorSourceSavedInProfile: false)
					} else {
						return .new
					}
				}
			}()
			state.modalDestinations = .firstLostPhoneHelper(.init(mode: mode))
			return .none

		case let .finished(simpleFactorConfig):

			switch state.mode {
			case let .new(new):
				precondition(new.lostPhoneHelper == simpleFactorConfig.singleRecoveryFactor)
				precondition(new.confirmerOfNewPhone == simpleFactorConfig.singleConfirmationFactor)

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

extension SecurityStructureConfiguration {
	var securityQuestionsFactorSource: SecurityQuestionsFactorSource {
		precondition(isSimple)
		return configuration.confirmationRole.thresholdFactors[0].extract(SecurityQuestionsFactorSource.self)!
	}
}

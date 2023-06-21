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

public typealias ListConfirmerOfNewPhone = FactorSourcesOfKindList<SecurityQuestionsFactorSource>
public typealias ListLostPhoneHelper = FactorSourcesOfKindList<TrustedContactFactorSource>

// MARK: - SimpleManageSecurityStructureFlow
public struct SimpleManageSecurityStructureFlow: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public enum Mode: Sendable, Hashable {
			case existing(SecurityStructureConfigurationDetailed)
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
			case updating(structure: SecurityStructureConfigurationDetailed)
			case creatingNew(config: SecurityStructureConfigurationDetailed.Configuration)
		}

		case updatedOrCreatedSecurityStructure(TaskResult<Product>)
	}

	public enum ChildAction: Sendable, Equatable {
		case modalDestinations(PresentationAction<ModalDestinations.Action>)
	}

	public struct ModalDestinations: Sendable, ReducerProtocol {
		public enum State: Sendable, Hashable {
			case listConfirmerOfNewPhone(ListConfirmerOfNewPhone.State)
			case listLostPhoneHelper(ListLostPhoneHelper.State)
		}

		public enum Action: Sendable, Equatable {
			case listConfirmerOfNewPhone(ListConfirmerOfNewPhone.Action)
			case listLostPhoneHelper(ListLostPhoneHelper.Action)
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.listConfirmerOfNewPhone, action: /Action.listConfirmerOfNewPhone) {
				ListConfirmerOfNewPhone()
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

	private func choseConfirmerOfNewPhone(
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

	private func choseLostPhoneHelper(
		_ factorSource: TrustedContactFactorSource,
		_ state: inout State
	) -> EffectTask<Action> {
		switch state.mode {
		case var .new(new):
			new.lostPhoneHelper = factorSource
			state.mode = .new(new)
		case var .existing(existing):
			// FIXME: Error handling
			try! existing.configuration.recoveryRole.changeFactorSource(to: factorSource)
			state.mode = .existing(existing)
		}
		state.modalDestinations = nil
		return .none
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .modalDestinations(.presented(.listConfirmerOfNewPhone(.delegate(.choseFactorSource(secQFS))))):
			return choseConfirmerOfNewPhone(secQFS, &state)

		case let .modalDestinations(.presented(.listLostPhoneHelper(.delegate(.choseFactorSource(trustedContactFS))))):
			return choseLostPhoneHelper(trustedContactFS, &state)

		default: return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .confirmerOfNewPhoneButtonTapped:
			switch state.mode {
			case let .existing(structure):
				precondition(structure.isSimple)
				state.modalDestinations = .listConfirmerOfNewPhone(.init(
					mode: .selection,
					selectedFactorSource: structure.securityQuestionsFactorSource
				))
			case .new:
				state.modalDestinations = .listConfirmerOfNewPhone(.init(
					mode: .selection
				))
			}
			return .none

		case .lostPhoneHelperButtonTapped:
			switch state.mode {
			case let .existing(structure):
				precondition(structure.isSimple)
				state.modalDestinations = .listLostPhoneHelper(.init(
					mode: .selection,
					selectedFactorSource: structure.trustedContactFactorSource
				))
			case .new:
				state.modalDestinations = .listLostPhoneHelper(.init(
					mode: .selection
				))
			}

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
						let config = SecurityStructureConfigurationDetailed.Configuration(from: simpleUnnamed)
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

extension SecurityStructureConfigurationDetailed.Configuration {
	init(from simple: SimpleUnnamedSecurityStructureConfig) {
		self.init(
			primaryRole: .single(simple.singlePrimaryFactor),
			recoveryRole: .single(simple.singleRecoveryFactor),
			confirmationRole: .single(simple.singleConfirmationFactor)
		)
	}
}

extension SecurityStructureConfigurationDetailed {
	var securityQuestionsFactorSource: SecurityQuestionsFactorSource {
		precondition(isSimple)
		return configuration.confirmationRole.thresholdFactors[0].extract(SecurityQuestionsFactorSource.self)!
	}
}

extension SecurityStructureConfigurationDetailed {
	var trustedContactFactorSource: TrustedContactFactorSource {
		precondition(isSimple)
		return configuration.recoveryRole.thresholdFactors[0].extract(TrustedContactFactorSource.self)!
	}
}

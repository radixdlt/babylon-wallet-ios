import ComposableArchitecture
import SwiftUI

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
				public var numberOfDaysUntilAutoConfirmation: RecoveryAutoConfirmDelayInDays = SecurityStructureConfigurationReference.Configuration.Recovery.defaultNumberOfDaysUntilAutoConfirmation

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
		public var destination: Destination.State?

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
		case changedNumberOfDaysUntilAutoConfirmation(String)
	}

	public enum DelegateAction: Sendable, Equatable {
		case updatedOrCreatedSecurityStructure(TaskResult<SecurityStructureProduct>)
	}

	public struct Destination: DestinationReducer {
		public enum State: Sendable, Hashable {
			case listConfirmerOfNewPhone(ListConfirmerOfNewPhone.State)
			case listLostPhoneHelper(ListLostPhoneHelper.State)
		}

		public enum Action: Sendable, Equatable {
			case listConfirmerOfNewPhone(ListConfirmerOfNewPhone.Action)
			case listLostPhoneHelper(ListLostPhoneHelper.Action)
		}

		public var body: some ReducerOf<Self> {
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

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	private func choseConfirmerOfNewPhone(
		_ factorSource: SecurityQuestionsFactorSource,
		_ state: inout State
	) -> Effect<Action> {
		switch state.mode {
		case var .new(new):
			new.confirmerOfNewPhone = factorSource
			state.mode = .new(new)
		case var .existing(existing):
			// FIXME: Error handling
			try! existing.configuration.confirmationRole.changeFactorSource(to: factorSource)
			state.mode = .existing(existing)
		}
		state.destination = nil
		return .none
	}

	private func choseLostPhoneHelper(
		_ factorSource: TrustedContactFactorSource,
		_ state: inout State
	) -> Effect<Action> {
		switch state.mode {
		case var .new(new):
			new.lostPhoneHelper = factorSource
			state.mode = .new(new)
		case var .existing(existing):
			// FIXME: Error handling
			try! existing.configuration.recoveryRole.changeFactorSource(to: factorSource)
			state.mode = .existing(existing)
		}
		state.destination = nil
		return .none
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case let .changedNumberOfDaysUntilAutoConfirmation(delayAsString):

			guard
				let raw = RecoveryAutoConfirmDelayInDays.RawValue(delayAsString)
			else {
				return .none
			}
			let delay = RecoveryAutoConfirmDelayInDays(rawValue: raw)

			switch state.mode {
			case var .existing(existing):
				precondition(existing.isSimple)
				existing.configuration.numberOfDaysUntilAutoConfirmation = delay
				state.mode = .existing(existing)
			case var .new(new):
				new.numberOfDaysUntilAutoConfirmation = delay
				state.mode = .new(new)
			}
			return .none

		case .confirmerOfNewPhoneButtonTapped:
			switch state.mode {
			case let .existing(structure):
				precondition(structure.isSimple)
				state.destination = .listConfirmerOfNewPhone(.init(
					kind: .securityQuestions,
					mode: .selection,
					selectedFactorSource: structure.securityQuestionsFactorSource
				))
			case .new:
				state.destination = .listConfirmerOfNewPhone(.init(
					kind: .securityQuestions,
					mode: .selection
				))
			}
			return .none

		case .lostPhoneHelperButtonTapped:
			switch state.mode {
			case let .existing(structure):
				precondition(structure.isSimple)
				state.destination = .listLostPhoneHelper(.init(
					kind: .trustedContact,
					mode: .selection,
					selectedFactorSource: structure.trustedContactFactorSource
				))
			case .new:
				state.destination = .listLostPhoneHelper(.init(
					kind: .trustedContact,
					mode: .selection
				))
			}

			return .none

		case let .finished(simpleFactorConfig):
			switch state.mode {
			case let .new(new):
				precondition(new.lostPhoneHelper == simpleFactorConfig.singleRecoveryFactor)
				precondition(new.confirmerOfNewPhone == simpleFactorConfig.singleConfirmationFactor)

				return .run { send in
					let taskResult = await TaskResult { () async throws -> SecurityStructureProduct in
						let primary = try await factorSourcesClient.getFactorSources(type: DeviceFactorSource.self).filter {
							!$0.supportsOlympia
						}.first!

						let config = SecurityStructureConfigurationDetailed.Configuration(
							numberOfDaysUntilAutoConfirmation: new.numberOfDaysUntilAutoConfirmation,
							primaryRole: .single(primary, for: .primary),
							recoveryRole: .single(simpleFactorConfig.singleRecoveryFactor, for: .recovery),
							confirmationRole: .single(simpleFactorConfig.singleConfirmationFactor, for: .confirmation)
						)
						return .creatingNew(config: config)
					}
					await send(.delegate(.updatedOrCreatedSecurityStructure(taskResult)))
				}

			case let .existing(structureToUpdate):
				return .send(.delegate(.updatedOrCreatedSecurityStructure(.success(.updating(structure: structureToUpdate)))))
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case let .listConfirmerOfNewPhone(.delegate(.choseFactorSource(secQFS))):
			choseConfirmerOfNewPhone(secQFS, &state)

		case let .listLostPhoneHelper(.delegate(.choseFactorSource(trustedContactFS))):
			choseLostPhoneHelper(trustedContactFS, &state)

		default:
			.none
		}
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

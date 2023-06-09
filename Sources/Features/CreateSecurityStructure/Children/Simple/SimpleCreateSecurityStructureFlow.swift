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
		case selectNewPhoneConfirmer
		case selectLostPhoneHelper
		case createSecurityStructure(TaskResult<SimpleUnnamedSecurityStructureConfig>)
	}

	@Dependency(\.factorSourcesClient) var factorSourcesClient

	public init() {}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .selectNewPhoneConfirmer:
			loggerGlobal.debug("'New phone confirmer' tapped")
			return .send(.delegate(.selectNewPhoneConfirmer))

		case .selectLostPhoneHelper:
			loggerGlobal.debug("'Lost phone helper' button tapped")
			return .send(.delegate(.selectLostPhoneHelper))

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

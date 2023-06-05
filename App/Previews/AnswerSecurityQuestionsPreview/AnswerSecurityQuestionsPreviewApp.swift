import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestions.State + EmptyInitializable
extension AnswerSecurityQuestions.State: EmptyInitializable {
	public init() {
		self.init(purpose: .encrypt(SecurityQuestionsFactorSource.defaultQuestions))
	}
}

// MARK: - AnswerSecurityQuestions.View + FeatureViewProtocol
extension AnswerSecurityQuestions.View: FeatureViewProtocol {
	public typealias Feature = AnswerSecurityQuestions
}

// MARK: - AnswerSecurityQuestions + PreviewedFeature
extension AnswerSecurityQuestions: PreviewedFeature {
	public typealias ResultFromFeature = TaskResult<AnswerSecurityQuestions.State.Purpose.AnswersResult>
}

// MARK: - AnswerSecurityQuestions.State.Purpose.AnswersResult + Encodable
extension AnswerSecurityQuestions.State.Purpose.AnswersResult: Encodable {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case let .encrypted(factor):
			try factor.encode(to: encoder)
		case let .decrypted(mnemonic):
			try mnemonic.encode(to: encoder)
		}
	}
}

// MARK: - AnswerSecurityQuestionsApp_
@main
struct AnswerSecurityQuestionsApp_: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<AnswerSecurityQuestions>.scene {
			guard case let .done(taskResult) = $0 else { return nil }
			return taskResult.
		}
	}
}

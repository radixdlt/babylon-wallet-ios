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
	public typealias ResultFromFeature = SecurityQuestionsFactorSource
}

// MARK: - AnswerSecurityQuestionsApp_
@main
struct AnswerSecurityQuestionsApp_: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<AnswerSecurityQuestions>.scene {
			guard case let .done(factorSource) = $0 else { return nil }
			return factorSource
		}
	}
}

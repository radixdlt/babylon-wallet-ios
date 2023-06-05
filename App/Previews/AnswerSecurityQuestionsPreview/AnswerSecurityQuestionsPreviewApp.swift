import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestions.State + EmptyInitializable
extension AnswerSecurityQuestions.State: EmptyInitializable {
	public init() {
		self.init(
			//			purpose: .encrypt(SecurityQuestionsFactorSource.defaultQuestions)
			purpose: .decrypt(
				// dilemma agree bind idea parade notable stock tuna buddy million nest day kitchen menu spell maple stand face cabin whip write lens hint february
				try! .fromJSON(
					"""
					 {
						"common" :  {
							"addedOn" : "2023-06-05T14:44:02Z",
							"cryptoParameters" :  {
								"supportedCurves" :  [
									"curve25519"
								],
								"supportedDerivationPathSchemes" :  [
									"cap26"
								]
							},
							"id" : "5e32c43a862b4274e9cd885bebe45a94c7f6d69e66cbb9cb97ca0639905ce80276",
							"lastUsedOn" : "2023-06-05T14:44:02Z"
						},
						"sealedMnemonic" :  {
							"encryptions" :  [
								"7d45e404e1590b0e3c254a5e194468ce3d9ab6252ad02dd98f4e7c43ea06bec63b1fe5bb07480506dda3b16dd1c631f37764326f376542c00559c0ab25f887ed243f625fe4c3e402aa43eb4dae7ca691043a41f87a20d7a3e22e5ca6e1fc2263dceaa862fecb21f66ee6e833c4ec2a1ae687cce7597eca8ee59b6938018bc8ffb2a1d0c7cd0fac9f264266cf19a6c52b157cb2219e9bd6845d850f4d082b1fe04adcd45a17d8a5e3350ae6d4384c",
								"083d6517575938faa61ac085088fc1153955b3076ec1e4ddbcd9fd8fab3d6be23c77b3348e5ab00f6a187de235883404fa0389b37be01e21d87aa0f0c1618dc0aeb6192a9de860829cdfe51377fd71e1ae7f0b3740bbf571655fa0fe728a38edea2934f15f858680dfec8027c397b844e91c98954a66c0aabe74b248a3c600ac1dab7890b451c895123ba9688d28a606161ccab5ad3899d6ec9e987f1bf0ae47ec1f433f8bd1a84c4cb9fe542e34",
								"934e08ac8e439b61c93adf037fb40cb01100fa05e4d1d48f5137424c79157334d6b8849a0609439baf4d48835c78a821bd1594deda93367a93e213d89ea2217422fbc9f586aec2d7ee27f23a0d3230bac2859a441b0a0b90c433a13e69f9233890830124a3975d74af91c55a0b936c248ba97fc3e05bb9be3214fac5e40cdb5f4ed35e5d6dfa02dbc1a38c207b15481d45f693b30f1399478101e47b7e49900487282036e1b5869e08757bb7123c",
								"bf89e796feb53c8ec17903c0d3a26dc86287f0b48122a78fd1f146e9a6a4e9d9e8c9e14b15fc89a2026e3395069d71d4c57dc15597104cc3ddf321a609d8c7100afb241311cb68de1af932a5bd55d26fac9ac3767b5b087bef1ac7cc6ae5fb1038e64e78d2b24192e7f5839ea1cb7e7ac0fbfb1b2ad7ca87f4737e4b5ac3ed753228e5a56a4b009369e98bc6f2d1cc8a5135b46caa83ec3cecd1568358d59718bf67833a4caffefdc3d3e2999488"
							],
							"securityQuestions" :  [
								 {
									"id" : 0,
									"kind" : "freeform",
									"question" : "Name of Radix DLT's Founder?",
									"version" : 1
								},
								 {
									"id" : 1,
									"kind" : "freeform",
									"question" : "Name of Radix DLT's CEO?",
									"version" : 1
								},
								 {
									"id" : 2,
									"kind" : "freeform",
									"question" : "Name of Radix DLT's CTO?",
									"version" : 1
								},
								 {
									"id" : 3,
									"kind" : "freeform",
									"question" : "Common first name amongst Radix DLT employees from Sweden?",
									"version" : 1
								}
							]
						}
					}
					"""
				)
			)
		)
	}
}

// MARK: - AnswerSecurityQuestions.View + FeatureViewProtocol
extension AnswerSecurityQuestions.View: FeatureViewProtocol {
	public typealias Feature = AnswerSecurityQuestions
}

// MARK: - AnswerSecurityQuestions + PreviewedFeature
extension AnswerSecurityQuestions: PreviewedFeature {
	public typealias ResultFromFeature = AnswerSecurityQuestions.State.Purpose.AnswersResult
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
			return taskResult
		}
	}
}

import Cryptography
extension SecurityQuestionsFactorSource {
	static func fromJSON(
		_ jsonString: String
	) throws -> Self {
		@Dependency(\.jsonDecoder) var jsonDecoder
		let data = jsonString.data(using: .utf8)!
		return try jsonDecoder().decode(SecurityQuestionsFactorSource.self, from: data)
	}
}

import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestionsCoordinator.State + EmptyInitializable
extension AnswerSecurityQuestionsCoordinator.State: EmptyInitializable {
	public init() {
		self.init(
			//						purpose: .encrypt(SecurityQuestionsFactorSource.defaultQuestions)
			purpose: .decrypt(try! .fromJSON(json))
		)
	}
}

// MARK: - AnswerSecurityQuestionsCoordinator.View + FeatureViewProtocol
extension AnswerSecurityQuestionsCoordinator.View: FeatureViewProtocol {
	public typealias Feature = AnswerSecurityQuestionsCoordinator
}

// MARK: - AnswerSecurityQuestionsCoordinator + PreviewedFeature
extension AnswerSecurityQuestionsCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = AnswerSecurityQuestionsCoordinator.State.Purpose.AnswersResult
}

// MARK: - AnswerSecurityQuestionsCoordinator.State.Purpose.AnswersResult + Encodable
extension AnswerSecurityQuestionsCoordinator.State.Purpose.AnswersResult: Encodable {
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
		FeaturesPreviewer<AnswerSecurityQuestionsCoordinator>.scene {
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

/// expect: `"stamp canvas project humble post satisfy easily term regular wheat feed ticket ecology absent desert flat custom erode scrub jelly coffee purity rebuild wink"`
private let json = """
 {
	"common" :  {
		"addedOn" : "2023-06-07T08:35:53Z",
		"cryptoParameters" :  {
			"supportedCurves" :  [
				"curve25519"
			],
			"supportedDerivationPathSchemes" :  [
				"cap26"
			]
		},
		"id" : "5e3c2c3afdd4d62920e1ba5288202ab9f4e747abf81c3a40330c5df966e052ccb7",
		"lastUsedOn" : "2023-06-07T08:35:53Z"
	},
	"sealedMnemonic" :  {
		"encryptions" :  [
			"0133af86be52840d01c80fafb5d13ed990000b83eca4f8f2e2cc9c98b7e7e541a71cc6bf8333790e3a88b4eac546fd7bf02534341a40841a33129a0d5913949ebc4712d92f139fb7585d6de689bd04ceb7c09b7cd5334f6aa1bf7e509a17fe8d59e108cea528d2e9911bb53a710dccce795f8929242ec4cb261f62ea9f6986515b5c52c3dbc6b54950bcbc9041d885d1ba1b5a8f3b12e788beddaa9b91e93aab7934430e494816fa07a9c0bda1389ece6754a0afe79428d47a04da",
			"6f4d0978fbbc60ea723bfdcd84aa91becb17c10015dff77f3bf2abbf470dd70de63ee9933c6e47ba52722989cc05edced8e4c929cc63843c7cb9605350287f519ec3eb5ff37cd552460096914a287446da46a6a10a39906855f40e21bab0bb85b3f37dee0f6082fbe285ff9889ac745e83061e47c4a83caa7acfce2bff0a251cb12a0f31ef0e08b6c3835403b0c03cea0ad78151a60f709304f87cd3249eb3cf25d8d7bc8c87d70c2a22f1c55f4376e2331db34f77441c18d8cf61",
			"d9bf65839a98e2535684a79b9d8190cfc2635e75f831bc1a5d2bcbadffa53abc028721b1eb71557820fc14b137a8c831228ee7a6015932eedd2900ebcbe5dcfca7594bfadeb3f1fe6a5a3840edf5272876b04aa44dcde7a49acc3e91a959ae2b1c4baff794977fa116381235b3ba12b66b0606ee82d482e6b4b87f858554e177d2eb568cb04131c0ac2ed2c1bed0cd8c4166a960b18c90784a2a6e794dc5993d72f41ff6e1f0373b2c2e046ef2d5105695c58179904475e4b9f00f",
			"4953d939f76593f6bee51284b491cbc2288282e2ce6ac5e412588866847d0692033bfc8b7f63e5367eb28499702b3d8837d3303706d1293f972bddc1be1f583d73b1e9bbb7a0648955e23669b785c5374b78e9f0eb518722cf4b82357dd691dc55a56cc66c0b33c1080282808d53b49fc34b9a3b5f773dee98e172bd922f7e7d9dbc2e7cd6ff6c0213ddac076839284a189378b7d3a4281311fdb1e1eea560ba5ef67c53f109bfc6a0beadf9354aca9a5e4a1e9820584fd0667be8"
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

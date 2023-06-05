import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestions.State + EmptyInitializable
extension AnswerSecurityQuestions.State: EmptyInitializable {
	public init() {
		self.init(
			//			purpose: .encrypt(SecurityQuestionsFactorSource.defaultQuestions)
			purpose: .decrypt(try! .fromJSON(json))
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

/// expect: `"call slim street lamp noble grunt fire moral artwork item write kind camp trouble dwarf iron twice damage popular confirm issue lunar behave fire"`
private let json = """
 {
	"common" :  {
		"addedOn" : "2023-06-05T15:01:58Z",
		"cryptoParameters" :  {
			"supportedCurves" :  [
				"curve25519"
			],
			"supportedDerivationPathSchemes" :  [
				"cap26"
			]
		},
		"id" : "5ebe9bf59ac38f18651b6f13a5a19979a39249e1419549e94422d09ae363c2ddc2",
		"lastUsedOn" : "2023-06-05T15:01:58Z"
	},
	"sealedMnemonic" :  {
		"encryptions" :  [
			"23e32b4ac1e4d682e2d32e1b5461f911636f7c4dc008a6c984da1e84574cda4f6229700ba633f79110a5a2a79a6684e45c1e9a9306a86ccdf03302b05f6557a6615d0833c1de7e696cd40922134dd3963fff9b112f7e953f56516f0dba4c4ef10250e7d7d1eb513d96930cb8be676d1fc9cee397c02624829f178bc292fc469c17276abe8cbfa7bae35f88db0a9afffdc20d6098e2b967ef73e287003bbe7a82be067e09c5d63a282ffe4975778285",
			"6c6ac47a0038c0a8ec892edeb4fcbf339ff6ea8500de09365ad040c7283094aed1f782a97652953daffe6d547fa0e2c3fcd4581d0ef7babade143336312d87ab6777d300721600975c3da8a808df568408d3de5a4c788a7cb67a175b51f7ceb8f5d878cb42ef8f46cfaa5fdcad2ce8d7c1dc7e842ef500cbd6f464afd0db44242389e7fd665fae7d0a1a85b0d2b13937554be85f8226e006ba13334ac4b9ea204f5c9959e6d44b90295b763d4ede3c",
			"680b1be6a1aebfc2902ad2e983ff739c265ae33118e786e2883dade70e22d479c99880418130228b7d4ae32cf58a4278f0fbfd1f2999560e78d9d4de50cf64104c9ad3d3989ad315405fb8328caa0e55667a37bb36799d862c107ff2d5f10d0ae30e7657b10c37fa452ad0c485cbd41a1180567f0fb769823a7b23f3589f68e3ae934b76706a4674be204a72e5d462c2b144562d90d3eae4ec720023016f26b5e84c0fbfab220c0bbe9b89f0060c83",
			"f5b15f3836830cd7f772d7428279415550e3ca96a671af8bc025f676e3acfb58edc6bcd613f72b6204f811798d4d11fb8b810fcfc1c7040f9a8601703659f5c76deb21236118d7d960204e02d7e21ddb3032aa024c723cdb3b04fbb012ad0a1fb9df8b048ba777fc3a9603f587219987fbbf92da559881b2db31d3eb75d613f419edf42750be8f229a9a911874883a932cc9832f0ca34df18efec1ba5a44559d258a9786adf2d9ef6792da726e7a90"
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

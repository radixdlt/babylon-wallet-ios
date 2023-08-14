import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestionsCoordinator.State + EmptyInitializable
extension AnswerSecurityQuestionsCoordinator.State: EmptyInitializable {
	public init() {
		self.init(
			/// expect: `"horn grass ticket ramp license matter volume film antenna school artefact script poem result culture gate learn minor when adjust jelly defense spring one"`
//			purpose: .encrypt
			purpose: .decrypt(try! .fromJSON(json))
		)
	}
}

// MARK: - AnswerSecurityQuestionsCoordinator.View + FeatureView
extension AnswerSecurityQuestionsCoordinator.View: FeatureView {
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
		FeaturesPreviewer<AnswerSecurityQuestionsCoordinator>.delegateAction {
			guard case let .done(taskResult) = $0 else { return nil }
			return taskResult
		} withReducer: {
			$0
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .noop)
				._printChanges()
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

private let json = """
{
	"common" : {
	  "addedOn" : "2023-08-14T13:46:56Z",
	  "cryptoParameters" : {
		"supportedCurves" : [
		  "curve25519"
		],
		"supportedDerivationPathSchemes" : [
		  "cap26"
		]
	  },
	  "flags" : [

	  ],
	  "lastUsedOn" : "2023-08-14T13:46:56Z"
	},
	"id" : {
	  "body" : "43efcc124fbaff4353ea6557ca17203659c0fa9cb05ce020bf49cef1e914f1f1",
	  "kind" : "securityQuestions"
	},
	"sealedMnemonic" : {
	  "encryptions" : [
		"1ef9c8b3c8114df8aac683bb7184bd8b22e6d66616e051cca8d016050228e325596639d41e2e62680d3342ab18f81803a476bbf6eae239ea6ebbf7d31037182e6de29dde4d297c671c224c15c5bceaa1efb640ac16b3c8dcfe70c5dcd78d575f64944ac0120ddc195090f7dba45c5bc58a76c82c788fd294ab93a5c256b5714bf426f0e52e00cd12678e8b74cecf0aec5f5d63f718e1c3f4d1575d6d11e056e49ea7fae07a5177fed39b3825df83b76d81e5529e02d3d033",
		"b1b72fb096887319f7ebcd5fc72a57c55e39a1cdcc94650902e1ddfcbde266b3c6eb7b74ef3bc0494856821eacc0d99cc2a674149ec5b733c5400bfb77bd933c67cb4a5f59548225b1d2f8562663e9a4d56bc942c8d0974c717e73821348675b09c78e731e601c68b1e81f0a5bd371b294b2d87317be6143a3578a322ac5a75c074092ada8fa3cf98f4d8f580b8691f71863912d15d92702a9a3539494c2c7ea1177408748040524b560b8822cd9e553797a2f4bd3a381ce",
		"cbeef7108fb3247e7eb0a9aef967556300d2b29dfbd2e68fd25a70cd8180a7232aa76facaedc3031743883d9aa89f833ab43c42b4f988be5bfa57b397d79cd5671b7a3a101cd4db36e554b476b38a366fc9f1f96bd040b4da5d1e19cc61c7fd795558c4c21c9f79dfe7c3a4d5f11ec572180852718ac7afc4490c3e600286f095c5602bd044d01577d78cb5e9963fb0050ed346eaa405a3f5273f6af420b52612d83b95f1fb3332c6a261094d6aa9e3af361352639a2be65",
		"f646f86bbba3ebccbdb008397bc8049a9e12dc7e4c4c88505c0939553b4cd10aacae6882600aadfef7a67d8b6bba6f7a7ecb3942c89b2dd269f93ab34f2bcb89b6b2144a60866440c35257990197b886e75346ddd010b452944065c838b608aa30e0d28a931c077f17d1797b7429ed822c4afa0557b11fe465f1476b5b03609d8e941db9dc89adafd20fb2b11a5613726c97156561a99a978cf1269b36868c35c3bbb8bacff7724fe7187bbda1ffcfd96b034227f3a0aa5d"
	  ],
	  "encryptionScheme" : "version1",
	  "securityQuestions" : [
		{
		  "id" : 0,
		  "kind" : "freeform",
		  "question" : "What's the first name of RDX Works Founder",
		  "version" : 1
		},
		{
		  "id" : 1,
		  "kind" : "freeform",
		  "question" : "What's the first name of RDX Works CEO",
		  "version" : 1
		},
		{
		  "id" : 2,
		  "kind" : "freeform",
		  "question" : "What's the first name of RDX Works CTO",
		  "version" : 1
		},
		{
		  "id" : 3,
		  "kind" : "freeform",
		  "question" : "What's the first name of RDX Works CPO",
		  "version" : 1
		}
	  ]
	}
  }
"""

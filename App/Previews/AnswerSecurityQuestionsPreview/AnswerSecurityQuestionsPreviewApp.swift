import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestionsCoordinator.State + EmptyInitializable
extension AnswerSecurityQuestionsCoordinator.State: EmptyInitializable {
	public init() {
		self.init(
			/// expect: `"walk warrior drive idle maid cherry connect slide slide phrase tower ability trash entry almost follow erupt egg trash tennis omit wing course sugar"`
//			purpose: .encrypt
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
	"common" :  {
		"addedOn" : "2023-06-09T12:30:28Z",
		"cryptoParameters" :  {
			"supportedCurves" :  [
				"curve25519"
			],
			"supportedDerivationPathSchemes" :  [
				"cap26"
			]
		},
		"id" : "5eec63f760a8d15b4e544bf334f5532b61ce741c28aa24475f49c472f33ac29d0e",
		"lastUsedOn" : "2023-06-09T12:30:28Z"
	},
	"sealedMnemonic" :  {
		"encryptions" :  [
			"df0056d91a2e9a0ed9337b666c737268e0f1ecd894de302774647ec63001149d80df8054906ef9432b01f9adc13782ad441efdf263dab355f7e841742e1d82779094f78e5ba54012294578dd864c3cc47b3a54bd95edd0116f0c0f9962849914a9109632742b5780b926249bda284fce2194ea3225278b0dee1ec317c6cdb5c3ef6b10bf939004b8e1cffa2fb00a0c7a24026cd844e84eb0334da318bae3681652d1f7d22913262773100b8c8d6dcd3a46d2",
			"0eddb0d0af54f52941dde0889d01c41b204fcce8e2b01e03a1244239150387f186807114a51e1f642026c8af3fffda722df5359b8a0dd7aee8395d044bd211c919bc8b4ec4e0e0aa5b6692a45e025664dfeadc2ba5bd02f8e34caa3cd3a11efac0751e3266df33df3ea8b00dd7c903dff632bfacf3e02ab639a03c15526d4e7908d96c031fe6c1959778e990dcc55a4583207d579b5b0d4d60c66768791800bd5aaa20f70c20c9e6f013d28b145ab69b4fca",
			"10414dd09216922a3b6b3e2e3398f2488e83bd13adc7f24cbbdf11161d3e72e8670ed307d25f2d55197e9e604877ec5c45056ddda681b86aa7e1fa79bcdbf5c5beeb67c8b9f69c824e67df3855ee5c5896d956925f25b47c948fb85d2ea516ed8e19fb9112aa84a4542878ef61856e7e00cece114cf87ab7a97e36472f07e66417b62f63eea2d2afaf847b10ce5d7a88bc0021511e55dd07d6ef1ff67b938cb4a825d5445439bd03a86947b44163138ef868",
			"68d1701a00e36376a3365cf151eb032a4de5fd9e00944404ddb0b6761f607ef9fe6dc0327a1d8b1d1f83ce5103fa913187e1ab99d12d8706817d1f054e27c5e54871612f7b54cb0c6a097ee46b39200d1b1f2a322620f8469be01a00805031f469434eb4d18fcf89a7715c9f83d4579d751aea445afcece2cccd20a803aad9390b0d36434f6bf94336cc7560df0b7b41c787991869ee2c9f25f8d0e974267d792c546816a7ece807693a5688f936dd1b9106"
		],
		"securityQuestions" :  [
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

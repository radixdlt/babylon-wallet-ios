import AnswerSecurityQuestionsFeature
import FeaturesPreviewerFeature

// MARK: - AnswerSecurityQuestionsCoordinator.State + EmptyInitializable
extension AnswerSecurityQuestionsCoordinator.State: EmptyInitializable {
	public init() {
		self.init(
			/// expect: `"anxiety hood wagon face actual burden slot knife express praise crew medal surface orbit disease car occur loop pink orient welcome current hedgehog afraid"`
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
	"common" :  {
		"addedOn" : "2023-08-17T11:28:24Z",
		"cryptoParameters" :  {
			"supportedCurves" :  [
				"curve25519"
			],
			"supportedDerivationPathSchemes" :  [
				"cap26"
			]
		},
		"flags" :  [
		],
		"lastUsedOn" : "2023-08-17T11:28:24Z"
	},
	"id" :  {
		"body" : "1bd0a4477c874fd2b317896a2ac2af3e4cae51add1c617d7ab6d710f3639ddc1",
		"kind" : "securityQuestions"
	},
	"sealedMnemonic" :  {
		"encryptionScheme" :  {
			"description" : "AESGCM-256",
			"version" : 1
		},
		"encryptions" :  [
			"83f49b1de8bab9037d618e68c2289e40df4a0738b23f5113ada824548cbd32237335a6955c2dd35c0343309ef04b9ebdd18fb37603bdbe5c66278b8294daa42e3d8a37c144c43e8b70ef18033281bfaefe61e1230c81f0a1a744064a653d5c8e3a774ef73a24a22c14f14a0604360c6d96834f611a45c331f0310cf4dda791be36a9a2f4f85cdc8bc308aae47817ddad2d101888a1c08fb0c881dbfa7b7d4cddbb2cade5d4d6ef45d82afa74b6cd01c8ab9c286f1df97182e4",
			"e68a46e279694716bcf8c3b252fee9cfd3f69339e6082bb791778b7d1f9bc3df69b94a109806b29d78ec36da6e750eaede1f800efc95d4fa685a22b5b26e4c5f6afe05bd73a921fb04ff5e78661708092409deb2883c2184a82c4699899125d3bdc23bf8d336fbc773ccb266b82fec7b4dcac5d69a1f7cc77a6992efb66e7a158ae903c237daca1e455c25106ad7b6db82ab8c7a59c2d8b2c200e243d28c8d16d29b95bcc4652a0ef608518290d705989e603e997bc09c3d14",
			"ddbfe02dd4281445afb25f9ad7f32b09e044d7fb1dec16f178736176bb1768ea85a601e086a2b75079c7159efbb6d8b04c26c4911d0d4f2c0132a0f6781832df31b43292366b317443998e0c7bc1663401d09b3bd252c06cc6c5214cddf20a9d0ea763aafa26d045ef544a5ad48b74bb97d94fbc008655f79564ff8c42f205735ff7f68d3258de7eeec7dc1bc185ed4e207e6f43224719ee8499f23442d53cadd9884d68154c6c9389b8c65c4b25ca94e89233c0487ac96c6a",
			"b0817c887d863af233166cbc10aa2fc40c9065576dbe38c4f4e1abd477872879961d50055f20272e0da8fc6e36d6eb183c4f54da59fe1b7f3da4b7f2c288a7c50d1eab0c01314f2b80d9a71cddefb94f4cd6671b00ca30ccbfa93335d2511d892f37be190ac013c5e58f20b560aba49103a19bc54de7c416da089db3808215cb8772229a45de76c33066d9c4ddecd2acfd6e283b3078853e7d2ec6d305e6f18e077d35f6ca7d35e17b81fa5d0baeb3915277a46033db0c5f77"
		],
		"keyDerivationScheme" :  {
			"description" : "Lowercase-remove-common-separator-chars-utf8-encode",
			"version" : 1
		},
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

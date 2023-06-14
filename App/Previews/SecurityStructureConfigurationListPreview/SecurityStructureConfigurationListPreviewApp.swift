import Cryptography
import FactorSourcesClient
import FeaturesPreviewerFeature
import SecurityStructureConfigurationListFeature

// MARK: - SecurityStructureConfigurationListCoordinator.State + EmptyInitializable
extension SecurityStructureConfigurationListCoordinator.State: EmptyInitializable {
	public init() {
		self.init(configList: .init())
	}
}

// MARK: - SecurityStructureConfigurationListCoordinator.View + FeatureView
extension SecurityStructureConfigurationListCoordinator.View: FeatureView {
	public typealias Feature = SecurityStructureConfigurationListCoordinator
}

// MARK: - SecurityStructureConfigurationListCoordinator + PreviewedFeature
extension SecurityStructureConfigurationListCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = SecurityStructureConfiguration
}

// MARK: - SecurityStructureConfigurationListPreviewApp
@main
struct SecurityStructureConfigurationListPreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<SecurityStructureConfigurationListCoordinator>.action {
			guard case let .child(.destination(.presented(.createSecurityStructureConfig(.delegate(.done(secStructureConfig)))))) = $0 else { return nil }
			return secStructureConfig

		} withReducer: {
			$0
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .previewApp)
				.dependency(\.appPreferencesClient, .previewApp)
				._printChanges()
		}
	}
}

extension FactorSourcesClient {
	static let previewApp: Self =
		with(noop) {
			$0.saveFactorSource = { _ in }
			$0.getFactorSources = { @Sendable in
				let device = try! DeviceFactorSource.babylon(
					mnemonicWithPassphrase: .init(
						mnemonic: Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
					)
				)
				return NonEmpty<IdentifiedArrayOf<FactorSource>>.init(rawValue: [device.embed()])!
			}
		}
}

import AppPreferencesClient
extension AppPreferencesClient {
	static let previewApp: Self = with(noop) {
		$0.updatePreferences = { _ in }
		$0.getPreferences = {
			var appPreferences = AppPreferences()
			var decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let configJSONStrings: [String] = [bestFriend, instabridge, colleague]
			appPreferences.security.structureConfigurations = .init(uncheckedUniqueElements: configJSONStrings.map {
				try! decoder.decode(SecurityStructureConfiguration.self, from: $0.data(using: .utf8)!)
			})
			return appPreferences
		}
	}
}

let bestFriend = """
{
	"id": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
	"configuration":
	{
		"confirmationRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "securityQuestions",
					"securityQuestions":
					{
						"id":
						{
							"kind": "securityQuestions",
							"body": "5b89016c6c7460b1d572ddd2678a28a6ac864cf4b6727620e9f28d5ca33ebcb0"
						},
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"sealedMnemonic":
						{
							"encryptions":
							[
								"9f3747d75021623702673ce24ee915696aa5f7d37048280fd5683617bae060aecb248e20108208ab90a913ec60c9a4c3756299b420bb64f59c3c17ef9dc8198cb01e011c7fa57aed126e4e6b920e7b49c1c7ca52ec2366c0c1b25bb3bcf199dc65fb2433d6fcf42e7f768068407fae24155deddfe08e00af1cb15797a9caf02532d628f4572bf408f21d12d1a8802fb015ce0a3b8badae0aeb14fb52f8332fd42653fd4aee40d53ef75d8f2585212fb78d50e640061b",
								"8bec1bdd0246168d41db3d4e3cb6746ffce4a3681ed4186c6a15460f6a59a7a86b4f53a574c76b283daa390e1fb9caf4427c97339f5445a2eb58e7c84503a38d4ea53038fed3fbd90cdcfb33d95a1a3328c8041a563935c3a535217e86f818ad83f82246db2e9fda11a114eaadabb64e2af7d6b9cb34b43884cb5e65c063f01950ad359224e2431f62daff95b5cb8b77a7dcbdbdbb3cfd66e3d3f4cc960e14056e016611ce99b36442ddc06a777324e84162b894e380",
								"c48197327ff5c22000194b8d6f0aef107680008b087770f8c95f1c8363727a7cdf814e8ea2963ae98a9cdcce02524eb9d8c2dfb4d006096e9d41faaf1b1e919f52ed4e31583d7d912aea65c03053b01f56296979bf9b5708c0241636d7143a3eeb8513fb1786e08070cbdc3a9d0415711957740ecd22b684c5294f86a38f795b903f7bcae21d678ef9b540f50e4ef732c763841c54fec6581e297de6b0d91979563e7e9331fe172b85126ad94217a10ccda8e515468d",
								"bf2027aa39bcc972e264edbc3bfb9a241150afe29ebc2a75cf9fd1244a722233cd9577f8ca5e26cc493aef1d54ec2804a9a50c778cd58ee6aab060e027ab1a6abc351e8f6032c3ffd35edbf89ff5aaeaab7e742ecc6789ea409155c723766a9031de781267b6e26df18c26e88088b005146c50a8d724428cfc857a6835491cf1a1e07dc116f8eb3ce5e89a8fb2d1a67a454c0e65d70eb3c61e4d31e20da6b8f9e546ec572d89b20715c7d522b1ce0ad97f446979eec9"
							],
							"securityQuestions":
							[
								{
									"id": 0,
									"kind": "freeform",
									"question": "What's the first name of RDX Works Founder",
									"version": 1
								},
								{
									"id": 1,
									"kind": "freeform",
									"question": "What's the first name of RDX Works CEO",
									"version": 1
								},
								{
									"id": 2,
									"kind": "freeform",
									"question": "What's the first name of RDX Works CTO",
									"version": 1
								},
								{
									"id": 3,
									"kind": "freeform",
									"question": "What's the first name of RDX Works CPO",
									"version": 1
								}
							]
						}
					}
				}
			]
		},
		"primaryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"device":
					{
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"id":
						{
							"kind": "device",
							"body": "09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
						},
						"hint":
						{
							"model": "",
							"name": ""
						},
						"nextDerivationIndicesPerNetwork":
						[]
					},
					"discriminator": "device"
				}
			]
		},
		"recoveryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "trustedContact",
					"trustedContact":
					{
						"id":
						{
							"kind": "trustedContact",
							"body": "account_tdx_c_1px0jul7a44s65568d32f82f0lkssjwx6f5t5e44yl6csqurxw3"
						},
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"contact":
						{
							"email": "hi@rdx.works",
							"name": "My friend"
						}
					}
				}
			]
		}
	},
	"createdOn": "2023-06-12T13:41:12Z",
	"lastUpdatedOn": "2023-06-12T13:41:12Z",
	"label": "Best friend"
}
"""

let instabridge = """
{
	"id": "A621E1F8-C36C-495A-93FC-0C247A3E6E5F",
	"configuration":
	{
		"confirmationRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "securityQuestions",
					"securityQuestions":
					{
						"id":
						{
							"kind": "securityQuestions",
							"body": "be10f8042632fc50c32dbb10f1d69a872b7a1547a644e1a28ed5692c97497023"
						},
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"sealedMnemonic":
						{
							"encryptions":
							[
								"5e5fcfc349e0dd9268be93d4292e8de8d6cd912b262f17918dbc5e90c1e2fcd57be1d98d8436766edb3c454f2c3c8cdce1cecad4ff57f09dd561973f0cfec3b14a73fa9f2caa68f792dc859235450a2b7a3cc5e6e8e7850d6b47338a154a5ec95e2241fc51def7836dd288aa7e595eef4d13a2dec58e76aa79dddf7f2574e2b10c01d446e56fb42fdc0e7ea35e6b13768baf1933373de7793b7eeaec38af9e9077ac615a0df99e485cd1ed2c63b6a16ac89285c12c7f11",
								"5389a2e507d4b9c94232f5b0a9ff0dadd54f5dc890b76a94ca1e7c719a24dc51f668aaab7c968d1b49d5328652f4f90a97c38c5401ecef476f8e4018a0ab111a47e1977e9e527bed7ce22093d980568cc7002d0e767ba5bf5cf89566498b1be34e9864c6297aa86fb909acde3a31006c63373c4de5d6107b7a0c7d49acfd8bf7523025b278071dcba356e74c9dd16c206369f26aaf907c9034fc6026513ef3763601f9e410cc8b0b45300bcbf7fbdffa4eda6cbf864468",
								"006b9428d09a2bf630f4b9871e8fbb1d8c0845dbb1717618aabeb529cf5dcbd63a32283a1f7a0885dedd6b8a6c5f25e040d9f1fca193c90ce645eaa82da61dd53083115b9c69db172d8beca4cfe5f2754bc26d8ec027bc15b07020241e504b4a3dff27e7767bc921ad2da280177435758a93ca5a6f2f64e0ce4ead7aa694f6a544a1bbe10519de61d38471f73fe8ab58fbe71b12c3607d1c283812b8bc616dbb19657b954c44e7f46f6f3466b3ef31e24fdf34eae4f384",
								"c810f8042632fc50c32dbb10f1d69a872b7a1547a644e1a28ed5692c97497023f55b3c6ca696f39f65136ff700708a1849818de2f81c6e5a21a0834d25f4cab8a60387b15b7db5dc91068926fe706dcc4dc80e69bf704ed196089d624ccde28b24287b4c265c421f31007ec7bb29f70bc9b803e96742556d565052e7e4d7847e3bccec8d54f33c6d1aa63e739110fc561a766bb538748aa3895c23328ac028c2438b1b7385e2f0dee96087e04ccf5950f65cadf75d63d8"
							],
							"securityQuestions":
							[
								{
									"id": 5,
									"kind": "freeform",
									"question": "What's the name of the first version of the Radix network (launch 2022)",
									"version": 1
								},
								{
									"id": 6,
									"kind": "freeform",
									"question": "What's the name of the second version of the Radix network (launch 2022)",
									"version": 1
								},
								{
									"id": 7,
									"kind": "freeform",
									"question": "What's the name of the third version of the Radix network (launch 2023)",
									"version": 1
								},
								{
									"id": 8,
									"kind": "freeform",
									"question": "What's the name of the fourth version of the Radix network (launch 2024)",
									"version": 1
								}
							]
						}
					}
				}
			]
		},
		"primaryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"device":
					{
						"id":
						{
							"kind": "device",
							"body": "09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
						},
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"hint":
						{
							"model": "",
							"name": ""
						},
						"nextDerivationIndicesPerNetwork":
						[]
					},
					"discriminator": "device"
				}
			]
		},
		"recoveryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "trustedContact",
					"trustedContact":
					{
						"id":
						{
							"kind": "trustedContact",
							"body": "account_tdx_c_1pyezed90u5qtagu2247rqw7f04vc7wnhsfjz4nf6vuvqtj9kcq"
						},
						"common":
						{
							"addedOn": "2023-06-12T13:39:09Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T13:39:09Z"
						},
						"contact":
						{
							"email": "Recover@instabridge.io",
							"name": "InstaBridge"
						}
					}
				}
			]
		}
	},
	"createdOn": "2023-06-12T13:41:12Z",
	"lastUpdatedOn": "2023-06-12T13:41:12Z",
	"label": "InstaBridge"
}
"""

let colleague = """
{
	"id": "0621E1F8-C36C-495A-93FC-0C247A3E6E5A",
	"configuration":
	{
		"confirmationRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "securityQuestions",
					"securityQuestions":
					{
						"id":
						{
							"kind": "securityQuestions",
							"body": "abbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabbaabba"
						},
						"common":
						{
							"addedOn": "2023-06-12T14:00:45Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T14:00:45Z"
						},
						"sealedMnemonic":
						{
							"encryptions":
							[
								"33d2b4de503467b7d9f6e95210a6a02783ef9422c2aa09578c261b3449164efd916b2877ab064b5be4acf3da9b0e24adadcfdc68efe56b8fbac4fd15a6902257ba337d13f7c8bf1349b48b2d7577e42d5e470aee78c5116f9a7c46abd7bf895b5921a00726a4a66ff7bc54981cddfccfe642500d10f7b8c8bd17dbe3d580c4f373230b660825b2db61a923f7b27a690635e835aa57a531f03668590b188ca2037c4a7abe74963b7f145d1d63e5f9fe2d1661d4adae5f77ec95e25a7843397815d82d",
								"1f0aa315be8105abcc7544c1f7e6f98f9fa422cb2d8905819f53f772efbc253f4bebd50466d187d5cd15d05722f5222df8160b128597b032fb5ce417318c5267e1c0c5d17e97bba32e2681ae7249ba8e4fa1b0c3cfd17e06506588c4a5e1b0c07a4dc57cf83508592180c350c524687e964715df3de936c9a055f23b542471582d7b8dd5abf9c6e90ecae9421d6752e16cfb4285d3bca1a53d2b90100a5f558bb04bff4c211a34f78e84c47262d1ed8dd58be1ce0765c6c2beb1a02a0caa20169bc7",
								"daaac8a8f06358355d4dd1d62caccf1c47acd960d3762feba7bd3ddd006ff31cc8a29e84e0a2f71bb07f8d2f590720349a87e85e9107366f475981d4b4ca18801530c00d3e16f10bb48fba82e841dba3233ed2f64269bba912d328770bc904922cd6b1bb24cb576d44046aa76192347c7a74ecaec08201c94489be0d42e97a921edbb164d06a6e1405d68e3178277b746ddccc0db326b92aafd406208124b2d02b7e078aa12601e8a6b0931c73b8b46918e2e44e63c9ebac55f06c6dcc95cce55598",
								"f75ba382f380a19e5eeb0354ecafe7594ed4089b7d72ec830f5347ca930a41fac7369aa48985c02b5c75c50d6f1ed1c03fc65b2eff814aea4ac3fcbe9557ae0357bf70016c5f6e144e4cb96f3602fa443446198471413ef1c27feadc8856f4a009fba9c61bc7b6ef30eb166b23fb9e4fc43878d766d7ca63339172d791a537f1b20d87dbeacb7178e8a21c2ce79078bbbd3699bcf73e00f8c2fb2050d1a3705ef3a8562e334bfcb7502ba93e00439fb990eae6521de86c412db3d214aa7d27a6bfae"
							],
							"securityQuestions":
							[
								{
									"id": 1,
									"kind": "freeform",
									"question": "What's the first name of RDX Works CEO",
									"version": 1
								},
								{
									"id": 2,
									"kind": "freeform",
									"question": "What's the first name of RDX Works CTO",
									"version": 1
								},
								{
									"id": 4,
									"kind": "freeform",
									"question": "What's a common first name amongst Swedish RDX Works employees",
									"version": 1
								},
								{
									"id": 5,
									"kind": "freeform",
									"question": "What's the name of the first version of the Radix network (launch 2022)",
									"version": 1
								}
							]
						}
					}
				}
			]
		},
		"primaryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"device":
					{
						"id": {
							"kind": "device",
							"body": "09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327"
						},
						"common":
						{
							"addedOn": "2023-06-12T14:00:45Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T14:00:45Z"
						},
						"hint":
						{
							"model": "",
							"name": ""
						},
						"nextDerivationIndicesPerNetwork":
						[]
					},
					"discriminator": "device"
				}
			]
		},
		"recoveryRole":
		{
			"superAdminFactors":
			[],
			"threshold": 1,
			"thresholdFactors":
			[
				{
					"discriminator": "trustedContact",
					"trustedContact":
					{
						"id":  {
							"kind": "trustedContact",
							"body": "account_tdx_c_1pygfwtlv7l90rcsge6t0f0jwn3cuzp05y8geek45qw7s98msmw"
						},
						"common":
						{
							"addedOn": "2023-06-12T14:00:45Z",
							"cryptoParameters":
							{
								"supportedCurves":
								[
									"curve25519"
								],
								"supportedDerivationPathSchemes":
								[
									"cap26"
								]
							},
							"lastUsedOn": "2023-06-12T14:00:45Z"
						},
						"contact":
						{
							"email": "coworker@rdx.works",
							"name": "Colleague"
						}
					}
				}
			]
		}
	},
	"createdOn": "2023-06-12T13:41:12Z",
	"lastUpdatedOn": "2023-06-12T13:41:12Z",
	"label": "Colleague"
}
"""

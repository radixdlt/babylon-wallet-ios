import Cryptography
import FeaturesPreviewerFeature
import ManageSecurityStructureFeature

// MARK: - ManageSecurityStructureCoordinator.State + EmptyInitializable
extension ManageSecurityStructureCoordinator.State: EmptyInitializable {
	public init() {
//		self.init(mode: .existing(existingStructure))
		self.init(mode: .new)
	}
}

// MARK: - ManageSecurityStructureCoordinator.View + FeatureView
extension ManageSecurityStructureCoordinator.View: FeatureView {
	public typealias Feature = ManageSecurityStructureCoordinator
}

// MARK: - ManageSecurityStructureCoordinator + PreviewedFeature
extension ManageSecurityStructureCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = SecurityStructureConfigurationDetailed
}

// MARK: - ManageSecurityStructurePreviewApp
@main
struct ManageSecurityStructurePreviewApp: SwiftUI.App {
	var body: some Scene {
		FeaturesPreviewer<ManageSecurityStructureCoordinator>.delegateAction {
			guard case let .done(secStructureConfig) = $0 else { return nil }
			return secStructureConfig
		} withReducer: {
			$0
				.dependency(\.date, .init {
					Date.now
				})
				.dependency(\.factorSourcesClient, .previewApp)
				.dependency(\.appPreferencesClient, .previewApp)
				._printChanges()
		}
	}
}

import FactorSourcesClient

extension FactorSourcesClient {
	static let previewApp: Self =
		update(noop) {
			$0.saveFactorSource = { _ in }
			$0.getFactorSources = { @Sendable in
				let device = try! DeviceFactorSource.babylon(
					mnemonicWithPassphrase: .init(
						mnemonic: Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo wrong", language: .english)
					)
				)
				return NonEmpty<IdentifiedArrayOf<FactorSource>>(rawValue: [device.embed()])!
			}
		}
}

import AppPreferencesClient

extension AppPreferencesClient {
	static let previewApp: Self = update(noop) {
		$0.updatePreferences = { _ in }
	}
}

let existingStructure: SecurityStructureConfigurationDetailed = try! {
	let json = instabridge.data(using: .utf8)!
	@Dependency(\.jsonDecoder) var decoder
	return try decoder().decode(SecurityStructureConfigurationDetailed.self, from: json)
}()

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
							"flags": [],
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
							"flags": [],
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
						}
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
							"flags": [],
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

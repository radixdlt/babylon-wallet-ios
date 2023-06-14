import Cryptography
import FeaturesPreviewerFeature
import ManageSecurityStructureFeature

// MARK: - ManageSecurityStructureCoordinator.State + EmptyInitializable
extension ManageSecurityStructureCoordinator.State: EmptyInitializable {
	public init() {
		self.init(mode: .existing(existingStructure))
	}
}

// MARK: - ManageSecurityStructureCoordinator.View + FeatureView
extension ManageSecurityStructureCoordinator.View: FeatureView {
	public typealias Feature = ManageSecurityStructureCoordinator
}

// MARK: - ManageSecurityStructureCoordinator + PreviewedFeature
extension ManageSecurityStructureCoordinator: PreviewedFeature {
	public typealias ResultFromFeature = SecurityStructureConfiguration
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
				.dependency(\.date, .constant(.now))
				.dependency(\.factorSourcesClient, .previewApp)
				.dependency(\.appPreferencesClient, .previewApp)
				._printChanges()
		}
	}
}

import FactorSourcesClient
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
	}
}

let existingStructure: SecurityStructureConfiguration = try! {
	let json =
		"""
		{
			 "configuration" :  {
				 "confirmationRole" :  {
					 "superAdminFactors" :  [
					 ],
					 "threshold" : 1,
					 "thresholdFactors" :  [
						  {
							 "discriminator" : "securityQuestions",
							 "securityQuestions" :  {
								 "common" :  {
									 "addedOn" : "2023-06-09T12:51:11Z",
									 "cryptoParameters" :  {
										 "supportedCurves" :  [
											 "curve25519"
										 ],
										 "supportedDerivationPathSchemes" :  [
											 "cap26"
										 ]
									 },
									 "id" : "5e35030ca23eb2c8407fe081675ba81f45c6afb893e7790e33721bd21012c96bcf",
									 "lastUsedOn" : "2023-06-09T12:51:11Z"
								 },
								 "sealedMnemonic" :  {
									 "encryptions" :  [
										 "bcd4f31dc79e3fdb246876d646e1902251c02a3d326902bbf9e21f5af5201f5db2eb3d0818eac3f63eefaf5eafa2534c196c60df06d84321b2374899adb37fb383730482b86801226ddb129ae3f0d30d4b378c9621a41e96a5956ae0286e73905574426bb2d820cf987529b42b5822055c1f89196d0fb2f34944aded1320da163732bbdb1c3b71de80c8898fdef8d5c3d91897815c1d2c2c841e561ec192a15d2d1665b9a36c8d8e0c76a12092",
										 "85675b7c2013dca1e84838d9eb12a29798b8970fc41f92a10f7fc6263d2e40634e0bbfe4f7a9dfa16cc2c9238596064a031c4c95222acf995baee3c6d795b3ef6a7b059fa21698347c73357bd44396cc6104dd3ccd6ecba385d51dcf601c3c365badd9b0e600f22b052f8f4a1823dd90df7613fe18cbd4995ce48a723315e1109ab472dac75622348e6c832c36cc5de2f747970b84850172ec1db95756b16ac7fbce4b6c473433195fd7eccdb7",
										 "a060a6a8496f4095c7c0e32599a102fd81a01dbdcf9fb40132674b02360b9dca89370916d226058c2da15cdb5e1ae96cbaa51bfc16086118291a23a0a555adcc404e303f2eb918a4f340426c6ce325045fb3002c909ac7616809021259e6b4adb5d9163f212cb00f0fd9a10f87c1a83db8726dd2c0c906e7e741212d79a1c5755375c77e342b60d414864327d702e0c52833f46a81331ff0d02f9bbf5accf1949d37bf83aaf7b6f07b5dad9e03",
										 "8d94bc8ca434ff852cb4988ac6a2d5c5375db45d8db9849f279cf23b0b428c0db9844f2b04a10898a0245f2629399af4721e36f859b3ed306aa158de08215559a6c5662a772e2ac05f5db8f174be2675eb9a215c1cf36115fdcb5865875c938de76b1e77959c126d29c5f40855cbbde38fbc893ac456c2b6aa281372cc996f2a30edb65898d36d359809f59b93f72b79a4fc48ccc309a4c85d625395981e21d2fc187612f1d767ad3517705c4c"
									 ],
									 "securityQuestions" :  [
										  {
											 "id" : 5,
											 "kind" : "freeform",
											 "question" : "What's the name of the first version of the Radix network (launch 2022)",
											 "version" : 1
										 },
										  {
											 "id" : 6,
											 "kind" : "freeform",
											 "question" : "What's the name of the second version of the Radix network (launch 2022)",
											 "version" : 1
										 },
										  {
											 "id" : 7,
											 "kind" : "freeform",
											 "question" : "What's the name of the third version of the Radix network (launch 2023)",
											 "version" : 1
										 },
										  {
											 "id" : 8,
											 "kind" : "freeform",
											 "question" : "What's the name of the fourth version of the Radix network (launch 2024)",
											 "version" : 1
										 }
									 ]
								 }
							 }
						 }
					 ]
				 },
				 "primaryRole" :  {
					 "superAdminFactors" :  [
					 ],
					 "threshold" : 1,
					 "thresholdFactors" :  [
						  {
							 "device" :  {
								 "common" :  {
									 "addedOn" : "2023-06-09T12:51:11Z",
									 "cryptoParameters" :  {
										 "supportedCurves" :  [
											 "curve25519"
										 ],
										 "supportedDerivationPathSchemes" :  [
											 "cap26"
										 ]
									 },
									 "id" : "de09a501e4fafc7389202a82a3237a405ed191cdb8a4010124ff8e2c9259af1327",
									 "lastUsedOn" : "2023-06-09T12:51:11Z"
								 },
								 "hint" :  {
									 "model" : "",
									 "name" : ""
								 },
								 "nextDerivationIndicesPerNetwork" :  [
								 ]
							 },
							 "discriminator" : "device"
						 }
					 ]
				 },
				 "recoveryRole" :  {
					 "superAdminFactors" :  [
					 ],
					 "threshold" : 1,
					 "thresholdFactors" :  [
						  {
							 "discriminator" : "trustedContact",
							 "trustedContact" :  {
								 "common" :  {
									 "addedOn" : "2023-06-09T12:51:11Z",
									 "cryptoParameters" :  {
										 "supportedCurves" :  [
											 "curve25519"
										 ],
										 "supportedDerivationPathSchemes" :  [
											 "cap26"
										 ]
									 },
									 "id" : "c0b636a2861106b805b353d1c972669a2f2eb764d5c0dfc38c69e3e81fe8665be7",
									 "lastUsedOn" : "2023-06-09T12:51:11Z"
								 },
								 "emailAddress" : "My@best.friend",
								 "name" : "Ghenadie"
							 }
						 }
					 ]
				 }
			 },
			 "created" : "2023-06-09T12:53:05Z",
			 "label" : "Main config"
		}

		""".data(using: .utf8)!

	@Dependency(\.jsonDecoder) var decoder
	return try decoder().decode(SecurityStructureConfiguration.self, from: json)
}()

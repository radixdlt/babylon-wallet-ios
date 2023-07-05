import ClientPrelude
import CryptoKit
import EngineToolkit
import EngineToolkitClient
import GatewaysClient
import Profile
import TestingPrelude
import TransactionClient

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	func test_accountsSuitableToPayTXFee_CREATE_FUNGIBLE_RESOURCE_then_deposit_batch() async throws {
		let transactionManifest = TransactionManifest(instructions: .string(
			"""
			                           CREATE_FUNGIBLE_RESOURCE
			                           18u8
			                           Map<String, Enum>(
			                             "name" =>  Enum<Metadata::String>("MyResource"),                                        # Resource Name
			                             "symbol" => Enum<Metadata::String>("RSRC"),                                            # Resource Symbol
			                             "description" => Enum<Metadata::String>("A very innovative and important resource")    # Resource Description
			                           )
			                           Map<Enum, Tuple>(
			                            Enum<ResourceMethodAuthKey::Withdraw>() => Tuple(Enum<AccessRule::AllowAll>(), Enum<AccessRule::DenyAll>()),
			                            Enum<ResourceMethodAuthKey::Deposit>() => Tuple(Enum<AccessRule::AllowAll>(), Enum<AccessRule::DenyAll>())
			                           );


			                           CALL_METHOD
			                               Address("account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			                               "deposit_batch"
			                               Expression("ENTIRE_WORKTOP");
			"""
		))

		let sut = TransactionClient.liveValue
		let expectedAccount = Profile.Network.Account.new(address: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
		try await withDependencies({
			$0.gatewaysClient.getCurrentGateway = { Radix.Gateway.simulator }
			$0.engineToolkitClient.analyzeManifest = { try EngineToolkitClient.liveValue.analyzeManifest($0) }
			$0.accountsClient.getAccountsOnNetwork = { _ in Profile.Network.Accounts(rawValue: .init(uncheckedUniqueElements: [expectedAccount]))! }
			$0.accountPortfoliosClient.fetchAccountPortfolios = { addresses, _ in try addresses.map {
				try .init(
					owner: $0,
					isDappDefintionAccountType: false,
					fungibleResources: .init(
						xrdResource: .init(
							resourceAddress: .init(validatingAddress: "resource_sim1thvwu8dh6lk4y9mntemkvj25wllq8adq42skzufp4m8wxxuemugnez"),
							amount: 11
						)
					),
					nonFungibleResources: []
				)
			} }
			$0.engineToolkitClient.getTransactionVersion = { .default }
			$0.engineToolkitClient.convertManifestInstructionsToJSONIfItWasString = EngineToolkitClient.liveValue.convertManifestInstructionsToJSONIfItWasString
		}, operation: {
			let res = try await sut.lockFeeBySearchingForSuitablePayer(transactionManifest, 10)
			switch res {
			case let .includesLockFee(incl):
				XCTAssertEqual(incl.feePayerSelectionAmongstCandidates.selected.account, expectedAccount)
			case .excludesLockFee:
				XCTFail("expected to have includesLockFee")
			}
		})
	}
}

extension Profile.Network.Account {
	static func new(address: String) -> Self {
		try! .init(
			networkID: .simulator,
			address: AccountAddress(validatingAddress: address),
			factorInstance: .init(
				factorSourceID: .previewValue,
				publicKey: .eddsaEd25519(Curve25519.Signing.PrivateKey().publicKey),
				derivationPath: AccountDerivationPath.babylon(.init(
					networkID: .simulator,
					index: 0,
					keyKind: .transactionSigning
				)).wrapAsDerivationPath()
			),
			displayName: "acc",
			extraProperties: .init(
				appearanceID: ._0
			)
		)
	}
}

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
			    Map<String, String>(
			        "name", "OwlToken",
			        "symbol", "OWL",
			        "description", "My Own Token if you smart - buy. If youre very smart, buy & keep"
			    )
			    Map<Enum, Tuple>(

			        Enum("ResourceMethodAuthKey::Withdraw"), Tuple(Enum("AccessRule::AllowAll"), Enum("AccessRule::DenyAll")),
			        Enum("ResourceMethodAuthKey::Deposit"), Tuple(Enum("AccessRule::AllowAll"), Enum("AccessRule::DenyAll"))
			    );


			CALL_METHOD
			    Address("account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64")
			    "deposit_batch"
			    Expression("ENTIRE_WORKTOP");
			"""
		))

		let sut = TransactionClient.liveValue
		let expectedAccount = Profile.Network.Account.new(address: "account_tdx_22_1pz8jpmse7hv0uueppwcksp2h60hkcdsfefm40cye9f3qlqau64")
		try await withDependencies({
			$0.gatewaysClient.getCurrentGateway = { Radix.Gateway.hammunet }
			$0.engineToolkitClient.analyzeManifest = { try EngineToolkitClient.liveValue.analyzeManifest($0) }
			$0.accountsClient.getAccountsOnNetwork = { _ in Profile.Network.Accounts(rawValue: .init(uncheckedUniqueElements: [expectedAccount]))! }
			$0.accountPortfoliosClient.fetchAccountPortfolios = { addresses, _ in addresses.map {
				.init(
					owner: $0,
					fungibleResources: .init(
						xrdResource: .init(
							resourceAddress: "resource_sim1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqzqu57yag",
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
			address: AccountAddress(address: address),
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

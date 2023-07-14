import ClientPrelude
import CryptoKit
import EngineKit
import GatewaysClient
import Profile
import TestingPrelude
import TransactionClient

// MARK: - TransactionClientTests
final class TransactionClientTests: TestCase {
	func test_accountsSuitableToPayTXFee_CREATE_FUNGIBLE_RESOURCE_then_deposit_batch() async throws {
		let transactionManifest = try TransactionManifest(
			instructions: .fromString(
				string:
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
				                               Address("account_tdx_21_12ya9jylskaa6gdrfr8nvve3pfc6wyhyw7eg83fwlc7fv2w0eanumcd")
				                               "deposit_batch"
				                               Expression("ENTIRE_WORKTOP");
				""",
				blobs: [],
				networkId: NetworkID.default.rawValue
			),
			blobs: []
		)

		let sut = TransactionClient.liveValue
		let expectedAccount = Profile.Network.Account.new(address: "account_tdx_21_12ya9jylskaa6gdrfr8nvve3pfc6wyhyw7eg83fwlc7fv2w0eanumcd")
		try await withDependencies({
			$0.gatewaysClient.getCurrentGateway = { Radix.Gateway.simulator }
			$0.accountsClient.getAccountsOnNetwork = { _ in Profile.Network.Accounts(rawValue: .init(uncheckedUniqueElements: [expectedAccount]))! }
			$0.accountPortfoliosClient.fetchAccountPortfolios = { addresses, _ in try addresses.map {
				try .init(
					owner: $0,
					isDappDefintionAccountType: false,
					fungibleResources: .init(
						xrdResource: .init(
							resourceAddress: .init(validatingAddress: "resource_tdx_21_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxsmgder"),
							amount: 11
						)
					),
					nonFungibleResources: []
				)
			} }
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

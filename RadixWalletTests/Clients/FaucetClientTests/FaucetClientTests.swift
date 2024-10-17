import JSONTesting
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - FaucetClientTests
final class FaucetClientTests: TestCase {
	let acco0 = try! AccountAddress(validatingAddress: "account_tdx_21_12ya9jylskaa6gdrfr8nvve3pfc6wyhyw7eg83fwlc7fv2w0eanumcd")
	let acco1 = try! AccountAddress(validatingAddress: "account_tdx_21_12xg7tf7aup8lrxkvug0vzatntzww0c6jnntyj6yd4eg5920kpxpzvt")

	func test_json_encoding_of_EpochForWhenLastUsedByAccountAddress() throws {
		var epochs = EpochForWhenLastUsedByAccountAddress()
		epochs.update(epoch: 2, for: acco0)
		epochs.update(epoch: 5, for: acco1)

		try XCTAssertJSONEncoding(
			epochs,
			[
				"epochForAccounts": [
					[
						"epoch": 2,
						"accountAddress": "account_tdx_21_12ya9jylskaa6gdrfr8nvve3pfc6wyhyw7eg83fwlc7fv2w0eanumcd",
					],
					[
						"epoch": 5,
						"accountAddress": "account_tdx_21_12xg7tf7aup8lrxkvug0vzatntzww0c6jnntyj6yd4eg5920kpxpzvt",
					],
				],
			]
		)
	}

	func test_json_decoding_of_EpochForWhenLastUsedByAccountAddress() throws {
		let json: JSON = [
			"epochForAccounts": [
				[
					"epoch": 2,
					"accountAddress": "account_tdx_21_12ya9jylskaa6gdrfr8nvve3pfc6wyhyw7eg83fwlc7fv2w0eanumcd",
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_21_12xg7tf7aup8lrxkvug0vzatntzww0c6jnntyj6yd4eg5920kpxpzvt",
				],
			],
		]

		try XCTAssertJSONDecoding(
			json,
			EpochForWhenLastUsedByAccountAddress(epochForAccounts: [
				.init(accountAddress: acco0, epoch: 2),
				.init(accountAddress: acco1, epoch: 5),
			])
		)
	}

	func test__GIVEN__no_persisted_json__WHEN__isAllowedToUseFaucet_is_called__THEN__true() async throws {
		let sut = FaucetClient.liveValue
		let userDefaults = UserDefaults.Dependency.ephemeral()
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { .irrelevant }
			$0.userDefaults = userDefaults
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_3__THEN__true() async throws {
		let sut = FaucetClient.liveValue

		let userDefaults = UserDefaults.Dependency.ephemeral()
		var epochs = EpochForWhenLastUsedByAccountAddress(epochForAccounts: [EpochForWhenLastUsedByAccountAddress.EpochForAccount(accountAddress: acco0, epoch: 2)])
		await userDefaults.saveEpochForWhenLastUsedByAccountAddress(epochs)
		await withDependencies {
			$0.userDefaults = userDefaults
			$0.gatewayAPIClient.getEpoch = { 3 }
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_4__THEN__true() async throws {
		let sut = FaucetClient.liveValue
		let userDefaults = UserDefaults.Dependency.ephemeral()
		var epochs = EpochForWhenLastUsedByAccountAddress(epochForAccounts: [EpochForWhenLastUsedByAccountAddress.EpochForAccount(accountAddress: acco0, epoch: 2)])
		await userDefaults.saveEpochForWhenLastUsedByAccountAddress(epochs)
		await withDependencies {
			$0.userDefaults = userDefaults
			$0.gatewayAPIClient.getEpoch = { 4 }
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_2__THEN__false() async throws {
		let sut = FaucetClient.liveValue
		let userDefaults = UserDefaults.Dependency.ephemeral()
		var epochs = EpochForWhenLastUsedByAccountAddress(epochForAccounts: [EpochForWhenLastUsedByAccountAddress.EpochForAccount(accountAddress: acco0, epoch: 2)])
		await userDefaults.saveEpochForWhenLastUsedByAccountAddress(epochs)
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { 2 }
			$0.userDefaults = userDefaults
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertFalse(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__allowed__WHEN__getFreeXRD_is_called__THEN__epoch_gets_saved_into_userDefaults() async throws {
		let sut = FaucetClient.liveValue
		let currentEpoch: Epoch = 1337
		let expectedEpochs = EpochForWhenLastUsedByAccountAddress(epochForAccounts: [
			.init(accountAddress: acco0, epoch: 2),
			.init(accountAddress: acco1, epoch: 5),
		])

		let userDefaults = UserDefaults.Dependency.ephemeral()
		await userDefaults.saveEpochForWhenLastUsedByAccountAddress(expectedEpochs)

		let hash = try IntentHash("txid_tdx_d_1pycj4pzxu9fc9x4qxflu63x7fmmal2raafd3wj9vea9nr5wy84dqsdq4cj")

		try await withDependencies {
			$0.gatewayAPIClient.getEpoch = { currentEpoch }
			$0.submitTXClient.submitTransaction = { _ in hash }
			$0.transactionClient.buildTransactionIntent = { _ in
				TransactionIntent.sample
			}
			$0.userDefaults = userDefaults
			$0.transactionClient.notarizeTransaction = { _ in
				NotarizeTransactionResponse(notarized: NotarizedTransaction.sample, intent: TransactionIntent.sample, txID: IntentHash.sample)
			}
			$0.submitTXClient.pollTransactionStatus = { _ in .success }
			$0.gatewaysClient.getCurrentGateway = { .enkinet }
		} operation: {
			try await sut.getFreeXRD(.init(recipientAccountAddress: acco0))
		}
	}
}

extension Epoch {
	static let irrelevant: Self = .init(0)
}

extension Curve25519.Signing.PublicKey {
	static let previewValue = try! Self(rawRepresentation: Data(hex: "573c0dc84196cb4a7dc8ddff1e92a859c98635a64ef5fe0bcf5c7fe5a7dab3e4"))
}

// extension Engine.EddsaEd25519PublicKey {
//	static let previewValue = Self(bytes: Array(Curve25519.Signing.PublicKey.previewValue.rawRepresentation))
// }

import ClientTestingPrelude
import CryptoKit
@testable import FaucetClient
import TransactionClient

// MARK: - FaucetClientTests
final class FaucetClientTests: TestCase {
	let acco0 = try! AccountAddress(address: "account_tdx_b_1pq53vs3xmykn9xx7a80ewt228fszw2cp440u6f69lpyqkrh82f")
	let acco1 = try! AccountAddress(address: "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu")
	let acco2 = try! AccountAddress(address: "account_tdx_b_1pr2q677ep9d5wxnhkkay9c6gvqln6hg3ul006w0a54tshau0z6")

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
						"accountAddress": "account_tdx_b_1pq53vs3xmykn9xx7a80ewt228fszw2cp440u6f69lpyqkrh82f",
					],
					[
						"epoch": 5,
						"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
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
					"accountAddress": "account_tdx_b_1pq53vs3xmykn9xx7a80ewt228fszw2cp440u6f69lpyqkrh82f",
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
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
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { .irrelevant }
			$0.userDefaultsClient.dataForKey = { key in
				XCTAssertEqual(key, epochForWhenLastUsedByAccountAddressKey)
				return nil
			}
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_3__THEN__true() async throws {
		let sut = FaucetClient.liveValue
		let json: JSON = [
			"epochForAccounts": [
				[
					"epoch": 2,
					"accountAddress": .string(acco0.address),
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
				],
			],
		]
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { 3 }
			$0.userDefaultsClient.dataForKey = { _ in json.data }
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_4__THEN__true() async throws {
		let sut = FaucetClient.liveValue
		let json: JSON = [
			"epochForAccounts": [
				[
					"epoch": 2,
					"accountAddress": .string(acco0.address),
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
				],
			],
		]
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { 4 }
			$0.userDefaultsClient.dataForKey = { _ in json.data }
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertTrue(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__persisted_json_with_epoch_2_WHEN__isAllowedToUseFaucet_is_called__and_epoch_eq_2__THEN__false() async throws {
		let sut = FaucetClient.liveValue
		let json: JSON = [
			"epochForAccounts": [
				[
					"epoch": 2,
					"accountAddress": .string(acco0.address),
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
				],
			],
		]
		await withDependencies {
			$0.gatewayAPIClient.getEpoch = { 2 }
			$0.userDefaultsClient.dataForKey = { _ in json.data }
		} operation: {
			let isAllowedToUseFaucet = await sut.isAllowedToUseFaucet(acco0)
			XCTAssertFalse(isAllowedToUseFaucet)
		}
	}

	func test__GIVEN__allowed__WHEN__getFreeXRD_is_called__THEN__epoch_gets_saved_into_userDefaults() async throws {
		let sut = FaucetClient.liveValue
		let json: JSON = [
			"epochForAccounts": [
				[
					"epoch": 2,
					"accountAddress": .string(acco0.address),
				],
				[
					"epoch": 5,
					"accountAddress": "account_tdx_b_1ppvvvxm3mpk2cja05fwhpmev0ylsznqfqhlewnrxg5gqmpswhu",
				],
			],
		]
		let currentEpoch: Epoch = 1337
		let expectedEpochs = EpochForWhenLastUsedByAccountAddress(epochForAccounts: [
			.init(accountAddress: acco0, epoch: currentEpoch),
			.init(accountAddress: acco1, epoch: 5),
		])
		try await withDependencies {
			$0.gatewayAPIClient.getEpoch = { currentEpoch }
			$0.submitTXClient.submitTransaction = { _ in .init("mocked_txid") }
			$0.transactionClient.buildTransactionIntent = { _ in
				TransactionIntentWithSigners(
					intent: .previewValue,
					notaryAndSigners: .init(
						notary: .init(
							notary: .ephemeralPublicKey(.eddsaEd25519(.previewValue))
						),
						accountsNeededToSign: NonEmpty(rawValue: [Profile.Network.Account.previewValue0])!
					),
					signerPublicKeys: []
				)
			}
			$0.engineToolkitClient.compileTransactionIntent = { _ in try .init(compiledIntentHex: "") }
			$0.transactionClient.notarizeTransaction = { _ in NotarizeTransactionResponse(notarized: .init(compiledIntent: []), txID: .init("mocked_txid")) }
			$0.submitTXClient.hasTXBeenCommittedSuccessfully = { _ in }
			$0.gatewaysClient.getCurrentGateway = { .nebunet }
			$0.engineToolkitClient.knownEntityAddresses = { _ in KnownEntityAddressesResponse.previewValue }
			$0.userDefaultsClient.dataForKey = { _ in json.data }
			$0.userDefaultsClient.setData = { maybeData, key in
				do {
					let data = try XCTUnwrap(maybeData)
					XCTAssertEqual(key, epochForWhenLastUsedByAccountAddressKey)
					let json = try JSON(data: data)
					try XCTAssertJSONDecoding(json, expectedEpochs)
				} catch {
					XCTFail("Expected no throw, but got: \(error)")
				}
			}
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

extension Engine.EddsaEd25519PublicKey {
	static let previewValue = Self(bytes: Array(Curve25519.Signing.PublicKey.previewValue.rawRepresentation))
}

extension TransactionHeader {
	static let previewValue = Self(
		version: .default,
		networkId: .kisharnet,
		startEpochInclusive: 0,
		endEpochExclusive: 1,
		nonce: 0,
		publicKey: .eddsaEd25519(.previewValue),
		notaryAsSignatory: true,
		costUnitLimit: 0,
		tipPercentage: 0
	)
}

extension TransactionIntent {
	static let previewValue = Self(header: .previewValue, manifest: TransactionManifest(instructions: ManifestInstructions.parsed([])))
}

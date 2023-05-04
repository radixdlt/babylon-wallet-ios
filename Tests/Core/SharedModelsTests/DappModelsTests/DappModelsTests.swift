@testable import SharedModels
import TestingPrelude

final class ToDappResponseTests: TestCase {
	func test_simple_rola() throws {
		let challenge: P2P.Dapp.AuthChallengeNonce = try .init(rawValue: .init(hex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"))
		let dAppDefinitionAddress = "account_tdx_c_1p93mejt0tl4vgsrafgyjqqx2mflsnhyutzs8ywre8zds7kgal0"
		let origin = "https://radix.swap"

		let usedButInaccurate = P2P.Dapp.Request.AuthLoginRequestItem.payloadToHash(
			challenge: challenge,
			origin: origin,
			dAppDefinitionAddress: dAppDefinitionAddress
		)

		XCTAssertEqual(usedButInaccurate.hex, "646561646265656664656164626565666465616462656566646561646265656664656164626565666465616462656566646561646265656664656164626565666163636f756e745f7464785f635f317039336d656a7430746c3476677372616667796a717178326d666c736e687975747a733879777265387a6473376b67616c3068747470733a2f2f72616469782e73776170")

		let notUsedButIshouldHAve = challenge.data.data + dAppDefinitionAddress.data(using: .utf8)! + origin.data(using: .utf8)!

		XCTAssertEqual(notUsedButIshouldHAve.hex, "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef6163636f756e745f7464785f635f317039336d656a7430746c3476677372616667796a717178326d666c736e687975747a733879777265387a6473376b67616c3068747470733a2f2f72616469782e73776170")
	}

	func test_encode_response() throws {
		let sut = P2P.Dapp.Response.success(.init(
			interactionId: "an_id",
			items: .request(
				.unauthorized(.init(
					oneTimeAccounts: .withoutProof(.init(
						accounts: [
							.init(
								accountAddress: try! .init(address: "address"),
								label: "Label",
								appearanceId: .fromIndex(0)
							),
						]
					)),
					oneTimePersonaData: .init(fields: [
						.init(field: .givenName, value: NonEmptyString(rawValue: "Percy")!),
						.init(field: .familyName, value: NonEmptyString(rawValue: "Jackson")!),
						.init(field: .emailAddress, value: NonEmptyString(rawValue: "lightningthief@olympus.lol")!),
						.init(field: .phoneNumber, value: NonEmptyString(rawValue: "555 5555")!),
					])
				))
			)
		))
		try print(JSON(of: sut))
		try XCTAssertJSONEncoding(
			sut,
			[
				"discriminator": "success",
				"interactionId": "an_id",
				"items": [
					"discriminator": "unauthorizedRequest",
					"oneTimeAccounts": [
						"accounts": [
							[
								"address": "address",
								"appearanceId": 0,
								"label": "Label",
							],
						],
					],
					"oneTimePersonaData": [
						"fields": [
							["field": "givenName", "value": "Percy"],
							["field": "familyName", "value": "Jackson"],
							["field": "emailAddress", "value": "lightningthief@olympus.lol"],
							["field": "phoneNumber", "value": "555 5555"],
						],
					],
				],
			]
		)
	}

	func test_decode_dApp_request_with_oneTimeAccountsRead_request_item() throws {
		let json: JSON = [
			"interactionId": "791638de-cefa-43a8-9319-aa31c582fc7d",
			"items": [
				"discriminator": "unauthorizedRequest",
				"oneTimeAccounts": [
					"numberOfAccounts": [
						"quantifier": "exactly",
						"quantity": 2,
					],
					"requiresProofOfOwnership": true,
				],
				"oneTimePersonaData": [
					"fields": ["givenName", "familyName", "emailAddress", "phoneNumber"],
				],
			],
			"metadata": [
				"networkId": 34,
				"origin": "radixdlt.dashboard.com",
				"dAppDefinitionAddress": "account_deadbeef",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.Request(
				id: "791638de-cefa-43a8-9319-aa31c582fc7d",
				items: .request(
					.unauthorized(.init(
						oneTimeAccounts: .init(
							numberOfAccounts: .exactly(2),
							requiresProofOfOwnership: true
						),
						oneTimePersonaData: .init(
							fields: [.givenName, .familyName, .emailAddress, .phoneNumber]
						)
					))
				),
				metadata: .init(
					networkId: 34,
					origin: "radixdlt.dashboard.com",
					dAppDefinitionAddress: try! .init(address: "account_deadbeef")
				)
			)
		)
	}

	func test_decode_dApp_request_with_sendTransactionWrite_request_item() throws {
		let json: JSON = [
			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
			"items": [
				"discriminator": "transaction",
				"send": [
					"version": 1,
					"transactionManifest": "",
					"message": "MSG",
				],
			],
			"metadata": [
				"networkId": 34,
				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
				"dAppDefinitionAddress": "account_deadbeef",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.Request(
				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
				items: .transaction(.init(
					send: .init(
						version: 1,
						transactionManifest: .init(instructions: .string("")),
						message: "MSG"
					)
				)),
				metadata: .init(
					networkId: 34,
					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
					dAppDefinitionAddress: try! .init(address: "account_deadbeef")
				)
			)
		)
	}
}

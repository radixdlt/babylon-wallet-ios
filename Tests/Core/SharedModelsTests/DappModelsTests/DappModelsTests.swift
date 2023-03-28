@testable import SharedModels
import TestingPrelude

final class ToDappResponseTests: TestCase {
	func test_encode_response() throws {
		let sut = P2P.ToDapp.WalletInteractionResponse.success(.init(
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
			P2P.FromDapp.WalletInteraction(
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
			P2P.FromDapp.WalletInteraction(
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

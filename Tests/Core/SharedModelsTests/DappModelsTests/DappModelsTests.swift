// @testable import SharedModels
// import TestingPrelude
//
//// MARK: - ToDappResponseTests
// final class ToDappResponseTests: TestCase {
//	func test_encode_response() throws {
//		let sut = P2P.Dapp.Response.success(.init(
//			interactionId: "an_id",
//			items: .request(
//				.unauthorized(.init(
//					oneTimeAccounts: P2P.Dapp.Response.WalletInteractionSuccessResponse.AccountsRequestResponseItem.withoutProofOfOwnership(accounts: [
//						.init(
//							accountAddress: try! .init(address: "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p"),
//							label: "Label",
//							appearanceId: .fromIndex(0)
//						),
//					]),
//					oneTimePersonaData: .init(fields: [
//						.init(field: .givenName, value: NonEmptyString(rawValue: "Percy")!),
//						.init(field: .familyName, value: NonEmptyString(rawValue: "Jackson")!),
//						.init(field: .emailAddress, value: NonEmptyString(rawValue: "lightningthief@olympus.lol")!),
//						.init(field: .phoneNumber, value: NonEmptyString(rawValue: "555 5555")!),
//					])
//
//				))
//			)
//		))
//		try print(JSON(of: sut))
//		try XCTAssertJSONEncoding(
//			sut,
//			[
//				"discriminator": "success",
//				"interactionId": "an_id",
//				"items": [
//					"discriminator": "unauthorizedRequest",
//					"oneTimeAccounts": [
//						"accounts": [
//							[
//								"address": "account_tdx_b_1p8ahenyznrqy2w0tyg00r82rwuxys6z8kmrhh37c7maqpydx7p",
//								"appearanceId": 0,
//								"label": "Label",
//							],
//						],
//					],
//					"oneTimePersonaData": [
//						"fields": [
//							["field": "givenName", "value": "Percy"],
//							["field": "familyName", "value": "Jackson"],
//							["field": "emailAddress", "value": "lightningthief@olympus.lol"],
//							["field": "phoneNumber", "value": "555 5555"],
//						],
//					],
//				],
//			]
//		)
//	}
//
//	func test_decode_dApp_request_with_oneTimeAccountsRead_request_item() throws {
//		let json: JSON = [
//			"interactionId": "791638de-cefa-43a8-9319-aa31c582fc7d",
//			"items": [
//				"discriminator": "unauthorizedRequest",
//				"oneTimeAccounts": [
//					"numberOfAccounts": [
//						"quantifier": "exactly",
//						"quantity": 2,
//					],
//					"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
//				],
//				"oneTimePersonaData": [
//					"fields": ["givenName", "familyName", "emailAddress", "phoneNumber"],
//				],
//			],
//			"metadata": [
//				"version": 1,
//				"networkId": 34,
//				"origin": "radixdlt.dashboard.com",
//				"dAppDefinitionAddress": "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6",
//			],
//		]
//		try XCTAssertJSONDecoding(
//			json,
//			P2P.Dapp.RequestUnvalidated(
//				id: "791638de-cefa-43a8-9319-aa31c582fc7d",
//				items: .request(
//					.unauthorized(.init(
//						oneTimeAccounts: .init(
//							numberOfAccounts: .exactly(2),
//							challenge: .init(rawValue: .init(data: .deadbeef32Bytes))
//						),
//						oneTimePersonaData: .init(
//							fields: [.givenName, .familyName, .emailAddress, .phoneNumber]
//						)
//					))
//				),
//				metadata: .init(
//					version: 1, networkId: 34,
//					origin: "radixdlt.dashboard.com",
//					dAppDefinitionAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"
//				)
//			)
//		)
//	}
//
//	func test_decode_dApp_request_with_sendTransactionWrite_request_item() throws {
//		let json: JSON = [
//			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//			"items": [
//				"discriminator": "transaction",
//				"send": [
//					"version": 1,
//					"transactionManifest": "",
//					"message": "MSG",
//				],
//			],
//			"metadata": [
//				"version": 1,
//				"networkId": 34,
//				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
//				"dAppDefinitionAddress": "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6",
//			],
//		]
//		try XCTAssertJSONDecoding(
//			json,
//			P2P.Dapp.RequestUnvalidated(
//				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//				items: .transaction(.init(
//					send: .init(
//						version: 1,
//						transactionManifest: .init(instructions: .string("")),
//						message: "MSG"
//					)
//				)),
//				metadata: .init(
//					version: 1, networkId: 34,
//					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
//					dAppDefinitionAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"
//				)
//			)
//		)
//	}
//
//	func test_decode_request_auth_without_challenge() throws {
//		let json: JSON = [
//			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//			"items": [
//				"discriminator": "authorizedRequest",
//				"auth": [
//					"discriminator": "loginWithoutChallenge",
//				],
//			],
//			"metadata": [
//				"version": 1,
//				"networkId": 34,
//				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
//				"dAppDefinitionAddress": "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6",
//			],
//		]
//		try XCTAssertJSONDecoding(
//			json,
//			P2P.Dapp.RequestUnvalidated(
//				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//				items: .request(.authorized(.init(
//					auth: .login(.withoutChallenge)
//				))),
//				metadata: .init(
//					version: 1,
//					networkId: 34,
//					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
//					dAppDefinitionAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"
//				)
//			)
//		)
//	}
//
//	func test_decode_request_auth_with_challenge() throws {
//		let json: JSON = [
//			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//			"items": [
//				"discriminator": "authorizedRequest",
//				"auth": [
//					"discriminator": "loginWithChallenge",
//					"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
//				],
//			],
//			"metadata": [
//				"version": 1,
//				"networkId": 34,
//				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
//				"dAppDefinitionAddress": "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6",
//			],
//		]
//		try XCTAssertJSONDecoding(
//			json,
//			P2P.Dapp.RequestUnvalidated(
//				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//				items: .request(.authorized(.init(
//					auth: .login(.withChallenge(.init(challenge: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")))
//				))),
//				metadata: .init(
//					version: 1,
//					networkId: 34,
//					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
//					dAppDefinitionAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"
//				)
//			)
//		)
//	}
//
//	func test_decode_request_auth_use_persona() throws {
//		let json: JSON = [
//			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//			"items": [
//				"discriminator": "authorizedRequest",
//				"auth": [
//					"discriminator": "usePersona",
//					"identityAddress": "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//				],
//			],
//			"metadata": [
//				"version": 1,
//				"networkId": 34,
//				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
//				"dAppDefinitionAddress": "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6",
//			],
//		]
//		try XCTAssertJSONDecoding(
//			json,
//			P2P.Dapp.RequestUnvalidated(
//				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
//				items: .request(.authorized(.init(
//					auth: .usePersona(.init(identityAddress: "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"))
//				))),
//				metadata: .init(
//					version: 1,
//					networkId: 34,
//					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
//					dAppDefinitionAddress: "account_tdx_c_1px26p5tyqq65809em2h4yjczxcxj776kaun6sv3dw66sc3wrm6"
//				)
//			)
//		)
//	}
//
//	func test_encode_response_auth_usePersona() throws {
//		let response = P2P.Dapp.Response.success(.init(
//			interactionId: "an_id",
//			items: .request(.authorized(.init(
//				auth: .usePersona(.init(
//					persona: .init(
//						identityAddress: "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//						label: "MrHyde"
//					)))
//			)))
//		))
//
//		try XCTAssertJSONEncoding(
//			response,
//			[
//				"discriminator": "success",
//				"interactionId": "an_id",
//				"items": [
//					"discriminator": "authorizedRequest",
//					"auth": [
//						"discriminator": "usePersona",
//						"persona": [
//							"identityAddress": "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//							"label": "MrHyde",
//						],
//					],
//				],
//			]
//		)
//	}
//
//	func test_encode_response_auth_login_without_challenge() throws {
//		let response = P2P.Dapp.Response.success(.init(
//			interactionId: "an_id",
//			items: .request(.authorized(.init(
//				auth: .login(.withoutChallenge(.init(
//					persona: .init(
//						identityAddress: "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//						label: "MrHyde"
//					)
//				)))
//			)))
//		))
//
//		try XCTAssertJSONEncoding(
//			response,
//			[
//				"discriminator": "success",
//				"interactionId": "an_id",
//				"items": [
//					"discriminator": "authorizedRequest",
//					"auth": [
//						"discriminator": "loginWithoutChallenge",
//						"persona": [
//							"identityAddress": "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//							"label": "MrHyde",
//						],
//					],
//				],
//			]
//		)
//	}
//
//	func test_encode_response_auth_login_with_challenge() throws {
//		let response = P2P.Dapp.Response.success(.init(
//			interactionId: "an_id",
//			items: .request(.authorized(.init(
//				auth: .login(.withChallenge(.init(
//					persona: .init(
//						identityAddress: "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//						label: "MrHyde"
//					),
//					challenge: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
//					proof: .init(
//						publicKey: "a82afd5c21188314e60b9045407b7dfad378ba5043bea33b86891f06d94fb1f3",
//						curve: .curve25519,
//						signature: "fadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeafdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
//					)
//				))))
//			))
//		)
//		)
//
//		try XCTAssertJSONEncoding(
//			response,
//			[
//				"discriminator": "success",
//				"interactionId": "an_id",
//				"items": [
//					"discriminator": "authorizedRequest",
//					"auth": [
//						"discriminator": "loginWithChallenge",
//						"persona": [
//							"identityAddress": "identity_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5",
//							"label": "MrHyde",
//						],
//						"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
//						"proof": [
//							"publicKey": "a82afd5c21188314e60b9045407b7dfad378ba5043bea33b86891f06d94fb1f3",
//							"curve": "curve25519",
//							"signature": "fadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeafdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
//						],
//					],
//				],
//			]
//		)
//	}
// }
//
//// MARK: - HexCodable32Bytes + ExpressibleByStringLiteral
// extension HexCodable32Bytes: ExpressibleByStringLiteral {
//	public init(stringLiteral: String) {
//		try! self.init(hex: stringLiteral)
//	}
// }

import Foundation
import JSONTesting
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - ToDappResponseTests
final class ToDappResponseTests: TestCase {
	let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.userInfo[.networkIdKey] = Radix.Gateway.default.network.id.rawValue
		return decoder
	}()

	func test_encode_response() throws {
		let sut = P2P.Dapp.Response.success(.init(
			interactionId: "an_id",
			items: .request(
				.unauthorized(.init(
					oneTimeAccounts: P2P.Dapp.Response.WalletInteractionSuccessResponse.AccountsRequestResponseItem.withoutProofOfOwnership(accounts: [
						.init(
							accountAddress: try! .init(validatingAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"),
							label: "Label",
							appearanceId: Profile.Network.Account.AppearanceID.fromNumberOfAccounts(0)
						),
					]),
					oneTimePersonaData: .init(
						name: .init(variant: .western, familyName: "Jackson", givenNames: "Percy", nickname: "Percy J"),
						emailAddresses: [.init(email: "lightningthief@olympus.lol")],
						phoneNumbers: [.init(number: "555 5555")]
					)

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
								"address": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
								"appearanceId": 0,
								"label": "Label",
							],
						],
					],
					"oneTimePersonaData": [
						"name": [
							"givenNames": "Percy",
							"familyName": "Jackson",
							"nickname": "Percy J",
							"variant": "western",
						],
						"emailAddresses": [
							"lightningthief@olympus.lol",
						],
						"phoneNumbers": [
							"555 5555",
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
					"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
				],
				"oneTimePersonaData": [
					"isRequestingName": true,
					"numberOfRequestedEmailAddresses": [
						"quantifier": "atLeast",
						"quantity": 1,
					],
					"numberOfRequestedPhoneNumbers": [
						"quantifier": "exactly",
						"quantity": 1,
					],
				],
			],
			"metadata": [
				"version": 1,
				"networkId": 34,
				"origin": "radixdlt.dashboard.com",
				"dAppDefinitionAddress": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.RequestUnvalidated(
				id: "791638de-cefa-43a8-9319-aa31c582fc7d",
				items: .request(
					.unauthorized(.init(
						oneTimeAccounts: .init(
							numberOfAccounts: .exactly(2),
							challenge: .init(rawValue: .init(data: .deadbeef32Bytes))
						),
						oneTimePersonaData: .init(
							isRequestingName: true,
							numberOfRequestedEmailAddresses: .atLeast(1),
							numberOfRequestedPhoneNumbers: .exactly(1)
						)
					))
				),
				metadata: .init(
					version: 1, networkId: 34,
					origin: "radixdlt.dashboard.com",
					dAppDefinitionAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"
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
				"version": 1,
				"networkId": 34,
				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
				"dAppDefinitionAddress": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.RequestUnvalidated(
				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
				items: .transaction(.init(
					send: .init(
						version: 1,
						transactionManifest: .init(
							instructions: .fromInstructions(
								instructions: [],
								networkId: Radix.Gateway.default.network.id.rawValue
							),
							blobs: []
						),
						message: "MSG"
					)
				)),
				metadata: .init(
					version: 1, networkId: 34,
					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
					dAppDefinitionAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"
				)
			),
			decoder: decoder
		)
	}

	func test_decode_request_auth_without_challenge() throws {
		let json: JSON = [
			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
			"items": [
				"discriminator": "authorizedRequest",
				"auth": [
					"discriminator": "loginWithoutChallenge",
				],
			],
			"metadata": [
				"version": 1,
				"networkId": 34,
				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
				"dAppDefinitionAddress": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.RequestUnvalidated(
				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
				items: .request(.authorized(.init(
					auth: .login(.withoutChallenge)
				))),
				metadata: .init(
					version: 1,
					networkId: 34,
					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
					dAppDefinitionAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"
				)
			),
			decoder: decoder
		)
	}

	func test_decode_request_auth_with_challenge() throws {
		let json: JSON = [
			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
			"items": [
				"discriminator": "authorizedRequest",
				"auth": [
					"discriminator": "loginWithChallenge",
					"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
				],
			],
			"metadata": [
				"version": 1,
				"networkId": 34,
				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
				"dAppDefinitionAddress": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.RequestUnvalidated(
				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
				items: .request(.authorized(.init(
					auth: .login(.withChallenge(.init(challenge: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")))
				))),
				metadata: .init(
					version: 1,
					networkId: 34,
					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
					dAppDefinitionAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"
				)
			),
			decoder: decoder
		)
	}

	func test_decode_request_auth_use_persona() throws {
		let json: JSON = [
			"interactionId": "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
			"items": [
				"discriminator": "authorizedRequest",
				"auth": [
					"discriminator": "usePersona",
					"identityAddress": "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650",
				],
			],
			"metadata": [
				"version": 1,
				"networkId": 34,
				"origin": "https://dashboard-pr-126.rdx-works-main.extratools.works",
				"dAppDefinitionAddress": "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn",
			],
		]
		try XCTAssertJSONDecoding(
			json,
			P2P.Dapp.RequestUnvalidated(
				id: "ed987de8-fc30-40d0-81ea-e3eef117a2cc",
				items: .request(.authorized(.init(
					auth: .usePersona(.init(identityAddress: "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650"))
				))),
				metadata: .init(
					version: 1,
					networkId: 34,
					origin: "https://dashboard-pr-126.rdx-works-main.extratools.works",
					dAppDefinitionAddress: "account_tdx_21_12yth59wfyl8e4axupym0c96g9heuf5j06lv2lgc2cuapzlmj6alzzn"
				)
			),
			decoder: decoder
		)
	}

	func test_encode_response_auth_usePersona() throws {
		let response = P2P.Dapp.Response.success(.init(
			interactionId: "an_id",
			items: .request(.authorized(.init(
				auth: .usePersona(.init(
					persona: .init(
						identityAddress: "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650",
						label: "MrHyde"
					)))
			)))
		))

		try XCTAssertJSONEncoding(
			response,
			[
				"discriminator": "success",
				"interactionId": "an_id",
				"items": [
					"discriminator": "authorizedRequest",
					"auth": [
						"discriminator": "usePersona",
						"persona": [
							"identityAddress": "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650",
							"label": "MrHyde",
						],
					],
				],
			]
		)
	}

	func test_encode_response_auth_login_without_challenge() throws {
		let response = P2P.Dapp.Response.success(.init(
			interactionId: "an_id",
			items: .request(.authorized(.init(
				auth: .login(.withoutChallenge(.init(
					persona: .init(
						identityAddress: "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650",
						label: "MrHyde"
					)
				)))
			)))
		))

		try XCTAssertJSONEncoding(
			response,
			[
				"discriminator": "success",
				"interactionId": "an_id",
				"items": [
					"discriminator": "authorizedRequest",
					"auth": [
						"discriminator": "loginWithoutChallenge",
						"persona": [
							"identityAddress": "identity_tdx_21_12tljxea3s0mse52jmpvsphr0haqs86sung8d3qlhr763nxttj59650",
							"label": "MrHyde",
						],
					],
				],
			]
		)
	}

	func test_encode_response_auth_login_with_challenge() throws {
		let response = P2P.Dapp.Response.success(.init(
			interactionId: "an_id",
			items: .request(.authorized(.init(
				auth: .login(.withChallenge(.init(
					persona: .init(
						identityAddress: "identity_tdx_21_1225rkl8svrs5fdc8rcmc7dk8wy4n0dap8da6dn58hptv47w9hmha5p",
						label: "MrHyde"
					),
					challenge: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
					proof: .init(
						publicKey: "a82afd5c21188314e60b9045407b7dfad378ba5043bea33b86891f06d94fb1f3",
						curve: .curve25519,
						signature: "fadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeafdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
					)
				))))
			))
		)
		)

		try XCTAssertJSONEncoding(
			response,
			[
				"discriminator": "success",
				"interactionId": "an_id",
				"items": [
					"discriminator": "authorizedRequest",
					"auth": [
						"discriminator": "loginWithChallenge",
						"persona": [
							"identityAddress": "identity_tdx_21_1225rkl8svrs5fdc8rcmc7dk8wy4n0dap8da6dn58hptv47w9hmha5p",
							"label": "MrHyde",
						],
						"challenge": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
						"proof": [
							"publicKey": "a82afd5c21188314e60b9045407b7dfad378ba5043bea33b86891f06d94fb1f3",
							"curve": "curve25519",
							"signature": "fadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeaffadedeafdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
						],
					],
				],
			]
		)
	}
}

// MARK: - HexCodable32Bytes + ExpressibleByStringLiteral
extension HexCodable32Bytes: ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(hex: stringLiteral)
	}
}

// MARK: - IdentityAddress + ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral, ExpressibleByStringLiteral
extension IdentityAddress: ExpressibleByExtendedGraphemeClusterLiteral & ExpressibleByUnicodeScalarLiteral & ExpressibleByStringLiteral {
	public init(stringLiteral: String) {
		try! self.init(validatingAddress: stringLiteral)
	}
}

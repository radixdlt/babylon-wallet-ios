import Foundation
import JSONTesting
@testable import Radix_Wallet_Dev
import XCTest

// MARK: - SnapshotJSONTests
final class SnapshotJSONTests: TestCase {
	func omit_test_generate() throws {
		let plaintextSnapshot: ProfileSnapshot = try readTestFixture(
			bundle: Bundle(for: Self.self),

			// This Profile was been built using the PROD version of app, version `1.0.0 (5)`
			// and exported as file and put here, then after app version 1.2.0 we have made the
			// following changes - which does NOT break backwards compatibility, hence we defer
			// bumping the Profile Snapshot JSON format version number (it remains at `100`):
			// * Added `flags` to Accounts/Personas with `deletedByUser` to support hide entities feature
			// * Removed `index` from UnsecuredEntityControl (migrating over to FactorSource based indexing)
			jsonName: "only_plaintext_profile_snapshot_version_100_patch_after_app_version_120",
			jsonDecoder: jsonDecoder
		)

		let vector = try SnapshotTestVector.encrypting(
			plaintext: plaintextSnapshot,
			mnemonics: [
				MnemonicWithPassphrase(
					mnemonic: .init(
						phrase: "alley urge tag valid execute hat little funny armed salute orient hurt balcony urban found clip tennis wrong turtle canoe castle exist pledge test",
						language: .english
					)
				),
				.init(
					mnemonic: .init(
						phrase: "gentle hawk winner rain embrace erosion call update photo frost fatal wrestle",
						language: .english
					)
				),
				.init(
					mnemonic: .init(
						phrase: "smile entry satisfy shed margin rubber disorder hungry foot error ribbon cradle aim round october blind lab spend",
						language: .english
					)
				),
			].map {
				try SnapshotTestVector.IdentifiableMnemonic(
					mnemonicWithPassphrase: $0
				)
			},
			passwords: [
				"",
				"Radix... just imagine!", // ref: https://github.com/radixdlt/radixdlt-swift-archive/blob/c289fa5bb8996fc427d2df064d9ae433665cac88/Tests/TestCases/UnitTests/RadixStack/3_Chemistry/AtomToExecutedActionMapper/DefaultAtomToTransactionMapperCreateTokenFromGenesisAtomTests.swift#L55
				"babylon",
			]
		)

		try XCTAssertJSONCoding(vector)

		try print(XCTUnwrap(String(data: jsonEncoder.encode(vector), encoding: .utf8)))
	}

	func test_profile_snapshot_version_100() throws {
		try testFixture(
			bundle: Bundle(for: Self.self),
			jsonName: "multi_profile_snapshots_test_version_100"
		) { (vector: SnapshotTestVector) in
			let decryptedSnapshots = try vector.validate()
			XCTAssertAllEqual(
				decryptedSnapshots.map(\.header.snapshotVersion),
				vector.plaintext.header.snapshotVersion,
				100
			)
			try XCTAssertJSONCoding(vector, encoder: jsonEncoder, decoder: jsonDecoder)
		}
	}

	func test_profile_snapshot_version_100_patch_after_app_version_120() throws {
		try testFixture(
			bundle: Bundle(for: Self.self),
			jsonName: "multi_profile_snapshots_test_version_100_patch_after_app_version_120"
		) { (vector: SnapshotTestVector) in
			let decryptedSnapshots = try vector.validate()
			XCTAssertAllEqual(
				decryptedSnapshots.map(\.header.snapshotVersion),
				vector.plaintext.header.snapshotVersion,
				100
			)
			try XCTAssertJSONCoding(vector, encoder: jsonEncoder, decoder: jsonDecoder)
		}
	}

	lazy var jsonEncoder: JSONEncoder = {
		let jsonEncoder = JSONEncoder.iso8601
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
		return jsonEncoder
	}()

	lazy var jsonDecoder: JSONDecoder = .iso8601

	func test_prof() throws {
		let jsonData = jsonString.data(using: .utf8)!
		let profile = try jsonDecoder.decode(ProfileSnapshot.self, from: jsonData)
	}
}

private let jsonString = """
{
    "header":
    {
        "creatingDevice":
        {
            "description": "moto g(60)s Motorola Moto g(60)s",
            "id": "be5af8cb-c64c-4f7f-a0a7-86ecd07184b7",
            "date": "2023-11-11T20:51:39Z"
        },
        "lastUsedOnDevice":
        {
            "description": "moto g(60)s Motorola Moto g(60)s",
            "id": "be5af8cb-c64c-4f7f-a0a7-86ecd07184b7",
            "date": "2023-11-11T20:51:39Z"
        },
        "id": "be5af8cb-c64c-4f7f-a0a7-86ecd07184b7",
        "lastModified": "2023-11-12T14:10:43Z",
        "snapshotVersion": 100,
        "contentHint":
        {
            "numberOfAccountsOnAllNetworksInTotal": 4,
            "numberOfPersonasOnAllNetworksInTotal": 1,
            "numberOfNetworks": 1
        }
    },
    "appPreferences":
    {
        "transaction":
        {
            "defaultDepositGuarantee": "1.0"
        },
        "display":
        {
            "fiatCurrencyPriceTarget": "usd",
            "isCurrencyAmountVisible": true
        },
        "security":
        {
            "isDeveloperModeEnabled": true,
            "structureConfigurationReferences":
            [],
            "isCloudProfileSyncEnabled": true
        },
        "gateways":
        {
            "current": "https://mainnet.radixdlt.com/",
            "saved":
            [
                {
                    "url": "https://mainnet.radixdlt.com/",
                    "network":
                    {
                        "id": 1,
                        "name": "mainnet",
                        "displayDescription": "Mainnet Gateway"
                    }
                },
                {
                    "url": "https://babylon-stokenet-gateway.radixdlt.com/",
                    "network":
                    {
                        "id": 2,
                        "name": "stokenet",
                        "displayDescription": "Stokenet (testnet) Gateway"
                    }
                }
            ]
        },
        "p2pLinks":
        [
            {
                "connectionPassword": "fa36b4b100026263b1ffcb295f69e71f9e07695f85f5fb713258853b3f324cdb",
                "displayName": "Notebook"
            }
        ]
    },
    "factorSources":
    [
        {
            "discriminator": "device",
            "device":
            {
                "id":
                {
                    "kind": "device",
                    "body": "66fe2b326a87e763cf05b77d2dc9b49c1ea457b6b0e7fc75a7e24dd30268c324"
                },
                "common":
                {
                    "cryptoParameters":
                    {
                        "supportedCurves":
                        [
                            "curve25519"
                        ],
                        "supportedDerivationPathSchemes":
                        [
                            "cap26"
                        ]
                    },
                    "addedOn": "2023-11-11T20:51:39Z",
                    "lastUsedOn": "2023-11-11T20:57:37Z",
                    "flags":
                    []
                },
                "hint":
                {
                    "model": "Moto g(60)s",
                    "name": "moto g(60)s",
                    "mnemonicWordCount": 24
                }
            }
        },
        {
            "discriminator": "ledgerHQHardwareWallet",
            "ledgerHQHardwareWallet":
            {
                "id":
                {
                    "kind": "ledgerHQHardwareWallet",
                    "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                },
                "common":
                {
                    "cryptoParameters":
                    {
                        "supportedCurves":
                        [
                            "secp256k1",
                            "curve25519"
                        ],
                        "supportedDerivationPathSchemes":
                        [
                            "cap26",
                            "bip44Olympia"
                        ]
                    },
                    "addedOn": "2023-11-11T20:55:21Z",
                    "lastUsedOn": "2023-11-11T20:55:21Z",
                    "flags":
                    []
                },
                "hint":
                {
                    "model": "nanoS+",
                    "name": "Ledger 1"
                }
            }
        },
        {
            "discriminator": "device",
            "device":
            {
                "id":
                {
                    "kind": "device",
                    "body": "0790204aad6e224390e991fcc2bfd5da27033bf2b64a9ba65ee7deb68f37d736"
                },
                "common":
                {
                    "cryptoParameters":
                    {
                        "supportedCurves":
                        [
                            "secp256k1",
                            "curve25519"
                        ],
                        "supportedDerivationPathSchemes":
                        [
                            "cap26",
                            "bip44Olympia"
                        ]
                    },
                    "addedOn": "2023-11-11T20:55:25Z",
                    "lastUsedOn": "2023-11-12T14:02:53Z",
                    "flags":
                    []
                },
                "hint":
                {
                    "model": "",
                    "name": "",
                    "mnemonicWordCount": 12
                }
            }
        },
        {
            "discriminator": "device",
            "device":
            {
                "id":
                {
                    "kind": "device",
                    "body": "77f80876f415c12b758fa2e8ee94eb9e74ee65bd456b66a3a1a7e8ff9a2fe141"
                },
                "common":
                {
                    "cryptoParameters":
                    {
                        "supportedCurves":
                        [
                            "secp256k1",
                            "curve25519"
                        ],
                        "supportedDerivationPathSchemes":
                        [
                            "cap26",
                            "bip44Olympia"
                        ]
                    },
                    "addedOn": "2023-11-11T21:23:08Z",
                    "lastUsedOn": "2023-11-11T21:38:44Z",
                    "flags":
                    []
                },
                "hint":
                {
                    "model": "",
                    "name": "",
                    "mnemonicWordCount": 24
                }
            }
        }
    ],
    "networks":
    [
        {
            "networkID": 1,
            "accounts":
            [
                {
                    "address": "account_rdx12ygh378czte87fdae4avmq9u3c2nxay42d0qf0qpfsclcgycza95ry",
                    "appearanceID": 0,
                    "displayName": "first",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 0,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/1H/525H/1460H/0H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "dac3b82158f8eae6243b4980aa5044ed3050252c1cfc251de12efafb9805f5e5",
                                                "curve": "curve25519"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "device",
                                        "body": "66fe2b326a87e763cf05b77d2dc9b49c1ea457b6b0e7fc75a7e24dd30268c324"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    [
                        "deletedByUser"
                    ]
                },
                {
                    "address": "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u",
                    "appearanceID": 1,
                    "displayName": "Stream",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 1,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/0H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "0245ea0756c93741133a36e420d3f51d46f44f976ffe015988291a9c84788e95cb",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "device",
                                        "body": "0790204aad6e224390e991fcc2bfd5da27033bf2b64a9ba65ee7deb68f37d736"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    []
                },
                {
                    "address": "account_rdx168mxgd4gwyt3ar2p6tz5c78gkezmtvd35nswy2aued4xh0mmja0x7m",
                    "appearanceID": 2,
                    "displayName": "Node",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 2,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/0H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "029f95bf867d91c7c9f92d6ed2696a0816a516e43cc9ac8c8d04f2418b35f7bbf4",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "ledgerHQHardwareWallet",
                                        "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    []
                },
                {
                    "address": "account_rdx16xmmhwyxhlm7upu6pxv9dk34m4c36duf7w3m8ecq9xzm6rjaazpk7y",
                    "appearanceID": 3,
                    "displayName": "Community Fund",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 3,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/1H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "0289d411da990cd98422c4e291f56b27e645670a3966a2c8c06baae2cdda9b0e63",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "ledgerHQHardwareWallet",
                                        "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    [
                        "deletedByUser"
                    ]
                },
                {
                    "address": "account_rdx16x62p6353ly0pz8k3et6pjlpeex2vuynmnphkm95uvpeuhg778ap7m",
                    "appearanceID": 4,
                    "displayName": "Node Reserve",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 4,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/2H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "035608728318572276e597ecbeb9a8748c05a5e76c54186891f190c5adad98ef6c",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "ledgerHQHardwareWallet",
                                        "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    [
                        "deletedByUser"
                    ]
                },
                {
                    "address": "account_rdx169dtk5c3v9mc9008x9jkyj04ta923fspmcp2yrff68m0gnwrg6ey2r",
                    "appearanceID": 5,
                    "displayName": "Radixscan Donations",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 5,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/3H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "038ef04b073f1a5bc0dc726fe41a7ce1324a3ab4cbb9aa9915d01812d8b5077849",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "ledgerHQHardwareWallet",
                                        "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    [
                        "deletedByUser"
                    ]
                },
                {
                    "address": "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722",
                    "appearanceID": 6,
                    "displayName": "Leo",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 6,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/4H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "035f597286b26cdec3b0d5e81f1ca7a185d69d29ea4947d56a110f7241bbd99173",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "ledgerHQHardwareWallet",
                                        "body": "9870f4f452b998d2679cbf6958803ebbc7165ea4fdcd308957b10a2a6b4b383a"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    []
                },
                {
                    "address": "account_rdx16xhz0tcdplq7g2etdw4nnapngr5rv4u60cyfuklql8e4pcqsr5ertm",
                    "appearanceID": 9,
                    "displayName": "Zeus",
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 9,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/0H/0/0H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "02ed13c63c5d41141125687fa4f25b7aa2d77d702aa80b1c132a80912dac70902c",
                                                "curve": "secp256k1"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "device",
                                        "body": "77f80876f415c12b758fa2e8ee94eb9e74ee65bd456b66a3a1a7e8ff9a2fe141"
                                    }
                                }
                            }
                        }
                    },
                    "onLedgerSettings":
                    {
                        "thirdPartyDeposits":
                        {
                            "depositRule": "acceptAll",
                            "assetsExceptionList":
                            [],
                            "depositorsAllowList":
                            []
                        }
                    },
                    "flags":
                    []
                }
            ],
            "personas":
            [
                {
                    "address": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                    "displayName": "Magal36 ",
                    "personaData":
                    {
                        "emailAddresses":
                        [],
                        "phoneNumbers":
                        [],
                        "urls":
                        [],
                        "postalAddresses":
                        [],
                        "creditCards":
                        []
                    },
                    "networkID": 1,
                    "securityState":
                    {
                        "discriminator": "unsecured",
                        "unsecuredEntityControl":
                        {
                            "entityIndex": 0,
                            "transactionSigning":
                            {
                                "badge":
                                {
                                    "discriminator": "virtualSource",
                                    "virtualSource":
                                    {
                                        "discriminator": "hierarchicalDeterministicPublicKey",
                                        "hierarchicalDeterministicPublicKey":
                                        {
                                            "derivationPath":
                                            {
                                                "path": "m/44H/1022H/1H/618H/1460H/0H",
                                                "scheme": "cap26"
                                            },
                                            "publicKey":
                                            {
                                                "compressedData": "7ddb9d67251e48fc2211c00efaba1d70ab904a5ec2aa866b05085f0bb7581bed",
                                                "curve": "curve25519"
                                            }
                                        }
                                    }
                                },
                                "factorSourceID":
                                {
                                    "discriminator": "fromHash",
                                    "fromHash":
                                    {
                                        "kind": "device",
                                        "body": "66fe2b326a87e763cf05b77d2dc9b49c1ea457b6b0e7fc75a7e24dd30268c324"
                                    }
                                }
                            }
                        }
                    },
                    "flags":
                    []
                }
            ],
            "authorizedDapps":
            [
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx12x0xfz2yumu2qsh6yt0v8xjfc7et04vpsz775kc3yd3xvle4w5d5k5",
                    "displayName": "Radix Dashboard",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T20:57:33Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u"
                                ],
                                "request":
                                {
                                    "quantifier": "atLeast",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx12yrjl8m5a4cn9aap2ez2lmvw6g64zgyqnlj4gvugzstye4gnj6assc",
                    "displayName": "Caviarnine",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T21:32:31Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u",
                                    "account_rdx168mxgd4gwyt3ar2p6tz5c78gkezmtvd35nswy2aued4xh0mmja0x7m",
                                    "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722",
                                    "account_rdx16xhz0tcdplq7g2etdw4nnapngr5rv4u60cyfuklql8e4pcqsr5ertm"
                                ],
                                "request":
                                {
                                    "quantifier": "atLeast",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx12x2ecj3kp4mhq9u34xrdh7njzyz0ewcz4szv0jw5jksxxssnjh7z6z",
                    "displayName": "Ociswap",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T21:35:17Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u",
                                    "account_rdx168mxgd4gwyt3ar2p6tz5c78gkezmtvd35nswy2aued4xh0mmja0x7m",
                                    "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722",
                                    "account_rdx16xhz0tcdplq7g2etdw4nnapngr5rv4u60cyfuklql8e4pcqsr5ertm"
                                ],
                                "request":
                                {
                                    "quantifier": "atLeast",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx16x5l69u3cpuy59g8n0g7xpv3u3dfmxcgvj8t7y2ukvkjn8pjz2v492",
                    "displayName": "ShardSpace",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T21:40:55Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u",
                                    "account_rdx168mxgd4gwyt3ar2p6tz5c78gkezmtvd35nswy2aued4xh0mmja0x7m",
                                    "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722",
                                    "account_rdx16xhz0tcdplq7g2etdw4nnapngr5rv4u60cyfuklql8e4pcqsr5ertm"
                                ],
                                "request":
                                {
                                    "quantifier": "atLeast",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx128ku70k3nxy9q0ekcwtwucdwm5jt80xsmxnqm5pfqj2dyjswgh3rm3",
                    "displayName": "Gable Finance",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T21:44:15Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722"
                                ],
                                "request":
                                {
                                    "quantifier": "exactly",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx128y905cfjwhah5nm8mpx5jnlkshmlamfdd92qnqpy6pgk428qlqxcf",
                    "displayName": "Astrolescent",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-11T21:44:43Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u",
                                    "account_rdx168mxgd4gwyt3ar2p6tz5c78gkezmtvd35nswy2aued4xh0mmja0x7m",
                                    "account_rdx169ljmarwjsftedcxt36cy8me7yaxgnuqz47dhe5gca889kgjgh0722",
                                    "account_rdx16xhz0tcdplq7g2etdw4nnapngr5rv4u60cyfuklql8e4pcqsr5ertm"
                                ],
                                "request":
                                {
                                    "quantifier": "atLeast",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                },
                {
                    "networkID": 1,
                    "dAppDefinitionAddress": "account_rdx168r05zkmtvruvqfm4rfmgnpvhw8a47h6ln7vl3rgmyrlzmfvdlfgcg",
                    "displayName": "Weft Finance",
                    "referencesToAuthorizedPersonas":
                    [
                        {
                            "identityAddress": "identity_rdx12f2nyj4l5p62cs24s7675x7lc3y06lj34az0eu4fvq4mdt0dp8nvr2",
                            "lastLogin": "2023-11-12T13:57:11Z",
                            "sharedAccounts":
                            {
                                "ids":
                                [
                                    "account_rdx16x0u3j2x3pw3w0jr0p7lzdvk07xuv23x64w9rarf9drn4736ttxf4u"
                                ],
                                "request":
                                {
                                    "quantifier": "exactly",
                                    "quantity": 1
                                }
                            },
                            "sharedPersonaData":
                            {}
                        }
                    ]
                }
            ]
        }
    ]
}
"""

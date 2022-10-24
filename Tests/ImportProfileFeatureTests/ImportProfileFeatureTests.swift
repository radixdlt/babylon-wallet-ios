import ComposableArchitecture
@testable import ImportProfileFeature
import Profile
import TestUtils

// MARK: - ImportProfileFeatureTests
@MainActor
final class ImportProfileFeatureTests: TestCase {
	let sut = TestStore(
		initialState: ImportProfile.State(),
		reducer: ImportProfile()
	)

	func test__GIVEN__action_goBack__WHEN__reducer_is_run__THEN__it_coordinates_to_goBack() async throws {
		_ = await sut.send(ImportProfile.Action.internal(.goBack))
		_ = await sut.receive(.coordinate(.goBack))
	}

	func test__GIVEN_fileImport_not_displayed__WHEN__user_wants_to_import_a_profile__THEN__fileImported_displayed() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: false),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.importProfileFile)) {
			$0.isDisplayingFileImporter = true
		}
	}

	func test__GIVEN_fileImport_displayed__WHEN__dismissed__THEN__fileImported_is_not_displayed_anymore() async throws {
		let sut = TestStore(
			initialState: ImportProfile.State(isDisplayingFileImporter: true),
			reducer: ImportProfile()
		)

		_ = await sut.send(.internal(.dismissFileimporter)) {
			$0.isDisplayingFileImporter = false
		}
	}

	func test__GIVEN__valid_profileSnapshot_json_data__WHEN__data_imported__THEN__data_gets_decoded() async throws {
		sut.dependencies.jsonDecoder = .iso8601
		_ = await sut.send(.internal(.importProfileDataResult(.success(exampleProfileSnapshotJSON))))
		_ = await sut.receive(.internal(.importProfileSnapshotFromDataResult(.success(ProfileSnapshot.example))))
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_imported__THEN__it_gets_saved() async throws {
		_ = await sut.send(.internal(.importProfileSnapshotFromDataResult(.success(.example))))
		_ = await sut.receive(.internal(.saveProfileSnapshot(.example)))
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_is_saved__THEN__reducer_calls_save_on_keychainClient() async throws {
		let keychainDataGotCalled = ActorIsolated<Data?>(nil)
		let keychainSetDataExpectation = expectation(description: "setDataForKey should be called on Keychain client")
		sut.dependencies.keychainClient.setDataDataForKey = { data, key in
			if key == "profileSnapshotKeychainKey" {
				Task {
					await keychainDataGotCalled.setValue(data)
					keychainSetDataExpectation.fulfill()
				}
			}
		}
		_ = await sut.send(.internal(.saveProfileSnapshot(ProfileSnapshot.example)))
		_ = await sut.receive(.internal(.saveProfileSnapshotResult(.success(ProfileSnapshot.example))))

		waitForExpectations(timeout: 1)
		try await keychainDataGotCalled.withValue {
			guard let jsonData = $0 else {
				XCTFail("Expected keychain to have set data for profile")
				return
			}
			let decoded = try JSONDecoder.iso8601.decode(ProfileSnapshot.self, from: jsonData)
			XCTAssertEqual(decoded, ProfileSnapshot.example)
		}
	}

	func test__GIVEN__a_valid_profileSnapshot__WHEN__it_has_been_saved__THEN__reducer_coordinates_to_parent_reducer() async throws {
		_ = await sut.send(.internal(.saveProfileSnapshotResult(.success(.example))))
		_ = await sut.receive(.coordinate(.importedProfileSnapshot(.example)))
	}
}

public extension ProfileSnapshot {
	static let example: Self = {
		let jsonDecoder = JSONDecoder.iso8601
		return try! jsonDecoder.decode(Self.self, from: exampleProfileSnapshotJSON)
	}()
}

private let exampleProfileSnapshotJSON = """
{
  "appPreferences" : {
      "browserExtensionConnections" : {
        "connections" : [
          {
            "browserName" : "Brave",
            "computerName" : "Mac Studio",
            "connectionPassword" : "deadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeafdeadbeeffadedeaf",
            "firstEstablishedOn" : "2022-10-19T14:31:30Z",
            "lastUsedOn" : "2022-10-19T14:31:30Z"
          }
        ]
      },
    "display" : {
      "fiatCurrencyPriceTarget" : "usd"
    }
  },
  "factorSources" : {
    "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources" : [
      {
        "creationDate" : "2022-10-19T13:40:27Z",
        "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
        "label" : "DeviceFactorSource"
      }
    ],
    "secp256k1OnDeviceStoredMnemonicHierarchicalDeterministicBIP44FactorSources" : [
      {
        "creationDate" : "2022-10-19T13:40:27Z",
        "factorSourceID" : "65cc68e58344fd2aef3c64e048054bafbf4ec311fc903a6fe4a400f095607120",
        "label" : "OlympiaFactorSource"
      }
    ]
  },
  "perNetwork" : [
    {
      "accounts" : [
        {
          "address" : {
            "address" : "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
          },
          "derivationPath" : "m/44H/1022H/10H/525H/0H/1238H",
          "displayName" : "First",
          "index" : 0,
          "securityState" : {
            "discriminator" : "unsecured",
            "unsecuredEntityControl" : {
              "genesisFactorInstance" : {
                "derivationPath" : {
                  "derivationPath" : "m/44H/1022H/10H/525H/0H/1238H",
                  "discriminator" : "accountPath"
                },
                "factorInstanceID" : "ad0fdd421d076068f77a71e8a46f0d4f2f2ead59d394370c8b5fd1ee5f6e59e0",
                "factorSourceReference" : {
                  "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
                  "factorSourceKind" : "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind"
                },
                "initializationDate" : "2022-10-18T08:16:22Z",
                "publicKey" : {
                  "compressedData" : "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b",
                  "curve" : "curve25519"
                }
              }
            }
          }
        },
        {
          "address" : {
            "address" : "account_tdx_a_1qvlrgnqrvk6tzmg8z6lusprl3weupfkmu52gkfhmncjsnhn0kp"
          },
          "derivationPath" : "m/44H/1022H/10H/525H/1H/1238H",
          "displayName" : "Second",
          "index" : 1,
          "securityState" : {
            "discriminator" : "unsecured",
            "unsecuredEntityControl" : {
              "genesisFactorInstance" : {
                "derivationPath" : {
                  "derivationPath" : "m/44H/1022H/10H/525H/1H/1238H",
                  "discriminator" : "accountPath"
                },
                "factorInstanceID" : "56831501ef03aca10f179cba84e491a804a9dcbdd6efcb2ec0334f128239029b",
                "factorSourceReference" : {
                  "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
                  "factorSourceKind" : "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind"
                },
                "initializationDate" : "2022-10-18T08:16:22Z",
                "publicKey" : {
                  "compressedData" : "b862c4ef84a4a97c37760636f6b94d1fba7b4881ac15a073f6c57e2996bbeca8",
                  "curve" : "curve25519"
                }
              }
            }
          }
        },
        {
          "address" : {
            "address" : "account_tdx_a_1qwum729sanm4ct2dc5cx49qh7xqxcmzcmqjhcvr9tsms5afgmd"
          },
          "derivationPath" : "m/44H/1022H/10H/525H/2H/1238H",
          "displayName" : "Third",
          "index" : 2,
          "securityState" : {
            "discriminator" : "unsecured",
            "unsecuredEntityControl" : {
              "genesisFactorInstance" : {
                "derivationPath" : {
                  "derivationPath" : "m/44H/1022H/10H/525H/2H/1238H",
                  "discriminator" : "accountPath"
                },
                "factorInstanceID" : "b04c92b9d87254635c4740eee54f0afe72db85cc153d3f3b4e5830b7bfb83303",
                "factorSourceReference" : {
                  "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
                  "factorSourceKind" : "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind"
                },
                "initializationDate" : "2022-10-18T08:16:22Z",
                "publicKey" : {
                  "compressedData" : "0f205737a6f38e84d7e001add0832018aa0b8768c6149afc506ea16d33fbad37",
                  "curve" : "curve25519"
                }
              }
            }
          }
        }
      ],
      "connectedDapps" : [

      ],
      "networkID" : 10,
      "personas" : [
        {
          "address" : {
            "address" : "account_tdx_a_1qdfqtthkmst0uv53ehhmlztn73zl7w90rannkh59rpds3clpnv"
          },
          "derivationPath" : "m/44H/1022H/10H/618H/0H/1238H",
          "displayName" : "Mrs Incognito",
          "fields" : [
            {
              "id" : "6E702A79-6B20-4E27-B93D-06A7BEFE9161",
              "kind" : "firstName",
              "value" : "Jane"
            },
            {
              "id" : "A5CEF5C8-6F26-43AA-9C68-1039ACF23CFE",
              "kind" : "lastName",
              "value" : "Incognitoson"
            }
          ],
          "index" : 0,
          "securityState" : {
            "discriminator" : "unsecured",
            "unsecuredEntityControl" : {
              "genesisFactorInstance" : {
                "derivationPath" : {
                  "derivationPath" : "m/44H/1022H/10H/618H/0H/1238H",
                  "discriminator" : "identityPath"
                },
                "factorInstanceID" : "8e2f33e7daccbc9b827c6db66f9ca4f55b242e9ad68deccb64bbc50af831d3a1",
                "factorSourceReference" : {
                  "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
                  "factorSourceKind" : "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind"
                },
                "initializationDate" : "2022-10-18T08:16:22Z",
                "publicKey" : {
                  "compressedData" : "3468508fcbb595be4bb7a6b45513d0141480cb1c47a38c625eae4b08ef4dce96",
                  "curve" : "curve25519"
                }
              }
            }
          }
        },
        {
          "address" : {
            "address" : "account_tdx_a_1qv25htyn66ax0pf4ygc60xk85w4yg2u2gyag8j3p25ksgaxuqd"
          },
          "derivationPath" : "m/44H/1022H/10H/618H/1H/1238H",
          "displayName" : "Mrs Public",
          "fields" : [
            {
              "id" : "616A7464-4C48-45CE-B374-BF5FED58F5BF",
              "kind" : "firstName",
              "value" : "Maria"
            },
            {
              "id" : "3302FDE9-996F-48AE-B868-E95C5C5AEF9F",
              "kind" : "lastName",
              "value" : "Publicson"
            }
          ],
          "index" : 1,
          "securityState" : {
            "discriminator" : "unsecured",
            "unsecuredEntityControl" : {
              "genesisFactorInstance" : {
                "derivationPath" : {
                  "derivationPath" : "m/44H/1022H/10H/618H/1H/1238H",
                  "discriminator" : "identityPath"
                },
                "factorInstanceID" : "6556a34a6d9bdcf2a59405d7075c50bf31669f1e49d8a769dfc3daaaaa584f8a",
                "factorSourceReference" : {
                  "factorSourceID" : "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1",
                  "factorSourceKind" : "curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind"
                },
                "initializationDate" : "2022-10-18T08:16:22Z",
                "publicKey" : {
                  "compressedData" : "dfe7b10d0623b7096ecfb7425500e06eb4820cbc75551fa46c70e87cb5d80f2c",
                  "curve" : "curve25519"
                }
              }
            }
          }
        }
      ]
    }
  ]
}

""".data(using: .utf8)!

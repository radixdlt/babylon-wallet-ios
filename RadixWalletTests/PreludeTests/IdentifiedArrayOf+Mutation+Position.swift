import Foundation
@testable import Radix_Wallet_Dev
import Sargon
import XCTest

// MARK: - IdentifiedArrayOfTests
final class IdentifiedArrayOfTests: XCTestCase {
	// https://github.com/pointfreeco/swift-identified-collections/pull/66
	func testIdentifiedArraySubscript() {
		struct ProtoAccount: Identifiable {
			let id: AccountAddress
		}
		var items: IdentifiedArrayOf<ProtoAccount> = [ProtoAccount(id: .sample), ProtoAccount(id: .sampleOther)]
		items[1] = ProtoAccount(id: .sampleStokenet)
		XCTAssertEqual(2, items.count)
		XCTAssertEqual([AccountAddress.sample, .sampleStokenet], items.map(\.id))
	}

	func test_crash() throws {
		let jsonData = Data(json.utf8)
		let sections = try JSONDecoder.iso8601.decode([TransactionHistory.TransactionSection].self, from: jsonData)
		let identifiedArray = IdentifiedArrayOf<TransactionHistory.TransactionSection>(uncheckedUniqueElements: sections, id: \.id)
		XCTAssertEqual(identifiedArray.count, sections.count)

		var unsorted = identifiedArray
		// this below does not crash
		unsorted.sort(by: { $0.day > $1.day })

		var unsorted2 = identifiedArray
		// this does not crash anymore - uses the method defined on IdentifiedArray
		unsorted2.sort(by: \.day, >)

		var elements = identifiedArray.elements
		// this never crashed - uses the method defined on RandomAccessCollection
		elements.sort(by: \.day, >)
	}
}

private let json = """
[
  {
    "day" : "2024-03-24T23:00:00Z",
    "month" : "2024-02-29T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "99"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          },
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "25"
                  },
                  "isXRD" : false
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "supplyIncreasable" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 0,
              "metadata" : {
                "dappDefinitions" : [
                  "account_tdx_2_129nx5lgkk3fz9gqf3clppeljkezeyyymqqejzp97tpk0r8els7hg3j"
                ],
                "description" : "Official Gumball Club candies, using only the finest sugar from decentralized markets.",
                "iconURL" : "https://stokenet-gumball-club.radixdlt.com/assets/candy-token.png",
                "name" : "GC Candies",
                "symbol" : "CANDY",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tk30vj4ene95e3vhymtf2p35fzl29rv4us36capu2rz0vretw9gzr3",
              "totalSupply" : "10262"
            }
          },
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "21"
                  },
                  "isXRD" : false
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "supplyIncreasableByAnyone" : {

                  }
                },
                {
                  "informationChangeableByAnyone" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://i.imgur.com/A2itmif.jpeg",
                "name" : "MyResource",
                "symbol" : "VIP",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1t5jzegxfgklzdh20naellhtq4l26jnxcgnx3z8nuhxdze0aa49dr6n",
              "totalSupply" : "100"
            }
          },
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "2"
                  },
                  "isXRD" : false
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "supplyIncreasableByAnyone" : {

                  }
                },
                {
                  "informationChangeableByAnyone" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://i.imgur.com/A2itmif.jpeg",
                "name" : "MyResource",
                "symbol" : "VIP",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1t5k76ndl0jaclzxl4ua85d4qx9xydhst633ads3rk524llp5wtgxwj",
              "totalSupply" : "100"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1zkh8h7vpzxjmrx58z74hmuz9mmtfgedutu0l3vdrs2cdm90xldzqw8vypv",
        "manifestClass" : "Transfer",
        "message" : "Hhhh",
        "time" : "2024-03-25T14:08:37Z",
        "withdrawals" : [

        ]
      }
    ]
  },
  {
    "day" : "2024-02-19T23:00:00Z",
    "month" : "2024-01-31T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "47"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_17nr2cdd9ggjcegd0cw50r839fg3r9kpy7fjef5ltpvtu5swaej9shljzsf",
        "manifestClass" : "Transfer",
        "time" : "2024-02-20T13:09:27Z",
        "withdrawals" : [

        ]
      },
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "1000"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1ahl9t0qnfq9shjdkwnlqkgvkrmr2d45ldsuerapx3x7dwvlnwensgc95r6",
        "manifestClass" : "Transfer",
        "time" : "2024-02-20T12:44:31Z",
        "withdrawals" : [

        ]
      },
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "1000"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1q0hlpx8a9x67mz23v5nvjz8vzsmnmjuwam3ed3gqjux0pz92qx9ssd60wr",
        "manifestClass" : "Transfer",
        "time" : "2024-02-20T12:13:44Z",
        "withdrawals" : [

        ]
      }
    ]
  },
  {
    "day" : "2024-02-11T23:00:00Z",
    "month" : "2024-01-31T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "URL With white space"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "URL with white space"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL Haze-medium.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#0#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Large"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Large"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-large.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#1#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "ICON Transparency PNG"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "ICON Transparency PNG"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/ICON-transparency.png"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#10#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "KL Haze Large"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "KL Haze Large"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-large.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#11#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "KL Haze Medium"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "KL Haze Medium"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-medium.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#12#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "KL Haze Small"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "KL Haze Small"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/KL+Haze-small.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#13#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 2"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 2"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-2.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#14#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 3"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 3"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano-3.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#15#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 0"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "modern kunst musem pano 0"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/modern_kunst_museum_pano.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#16#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Scryptonaut Patch SVG"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Scryptonaut Patch SVG"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/scryptonaut_patch.svg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#17#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Medium"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Medium"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-medium.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#2#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Small"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Filling Station Breakfast Small"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Filling+Station+Breakfast-small.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#3#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Frame 6 Large"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Frame 6 Large"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-large.png"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#4#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Frame 6 Medium"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Frame 6 Medium"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-medium.png"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#5#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Frame 6 Small"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Frame 6 Small"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Frame+6-small.png"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#6#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Kway Teow Large"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Kway Teow Large"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-large.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#7#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Kway Teow Medium"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Kway Teow Medium"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-medium.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#8#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          },
          {
            "details" : {
              "nonFungible" : {
                "_0" : {
                  "data" : {
                    "fields" : [
                      {
                        "field_name" : "name",
                        "kind" : "String",
                        "value" : "Kway Teow Small"
                      },
                      {
                        "field_name" : "description",
                        "kind" : "String",
                        "value" : "Kway Teow Small"
                      },
                      {
                        "field_name" : "key_image_url",
                        "kind" : "String",
                        "type_name" : "Url",
                        "value" : "https://image-service-test-images.s3.eu-west-2.amazonaws.com/wallet_test_images/Fried+Kway+Teow-small.jpg"
                      },
                      {
                        "field_name" : "arbitrary_coolness_rating",
                        "kind" : "U64",
                        "value" : "45"
                      }
                    ],
                    "kind" : "Tuple",
                    "type_name" : "MetadataStandardNonFungibleData"
                  },
                  "id" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw:#9#"
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "simpleAsset" : {

                  }
                }
              ],
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://upload.wikimedia.org/wikipedia/commons/b/be/VeKings.png",
                "name" : "SandboxNFT",
                "tags" : [
                  {
                    "custom" : {
                      "_0" : "collection"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "sandbox"
                    }
                  },
                  {
                    "custom" : {
                      "_0" : "example-tag"
                    }
                  }
                ]
              },
              "resourceAddress" : "resource_tdx_2_1ngcwcdvheaecsz55wx7hkc8946zuyhtnzp4gkspwqfnecap377pnlw",
              "totalSupply" : "18"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1r88ruwlavhcxa7aqfmtwj6za523cvpy74f7cv7qvl9yld58qrgfsru53v7",
        "manifestClass" : "General",
        "time" : "2024-02-12T13:54:19Z",
        "withdrawals" : [

        ]
      },
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "100"
                  },
                  "isXRD" : false
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91718764
              },
              "behaviors" : [
                {
                  "supplyIncreasableByAnyone" : {

                  }
                },
                {
                  "informationChangeableByAnyone" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "A very innovative and important resource",
                "iconURL" : "https://i.imgur.com/A2itmif.jpeg",
                "name" : "MyResource",
                "symbol" : "VIP",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1thet4cr72jzqnypp0a8708nh8qxtqg7awv5achcx4z963z2uzgg0mw",
              "totalSupply" : "100"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1msyplm7ke4n3lkekf4rn0jpfputfj4dxvqx9uu336cejgkhqg3ysnvnfj3",
        "manifestClass" : "General",
        "time" : "2024-02-12T13:49:47Z",
        "withdrawals" : [

        ]
      }
    ]
  },
  {
    "day" : "2024-02-05T23:00:00Z",
    "month" : "2024-01-31T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [

        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1k0vlxcvxh886saxa50sv3k87whqza0epwnfl74hjd4m3rggy507q6yc6t5",
        "manifestClass" : "Transfer",
        "message" : "Hsbddndn",
        "time" : "2024-02-06T14:10:10Z",
        "withdrawals" : [

        ]
      }
    ]
  },
  {
    "day" : "2024-05-12T22:00:00Z",
    "month" : "2024-04-30T22:00:00Z",
    "transactions" : [
      {
        "deposits" : [

        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_186azw5cehmpafe83trfwcplaxs7d0g403ec7qrh9e4kymkkahlksvzu972",
        "manifestClass" : "Transfer",
        "time" : "2024-05-13T12:05:30Z",
        "withdrawals" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "12"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ]
      }
    ]
  },
  {
    "day" : "2024-03-28T23:00:00Z",
    "month" : "2024-02-29T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [

        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1qruax0e28rk3ljmy62z8rx6l7fj0v6kwaztn0aj33tryltrdldqsvaf3w9",
        "manifestClass" : "Transfer",
        "time" : "2024-03-29T14:08:13Z",
        "withdrawals" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "9999"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ]
      }
    ]
  },
  {
    "day" : "2024-02-01T23:00:00Z",
    "month" : "2024-01-31T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [

        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1p80y2d7hfyksxr6ugku67zg33rmhs0ze89ncvqmdqfetfg2f45ysx0v50h",
        "manifestClass" : "Transfer",
        "time" : "2024-02-02T16:25:11Z",
        "withdrawals" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "676"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ]
      }
    ]
  },
  {
    "day" : "2023-12-12T23:00:00Z",
    "month" : "2023-11-30T23:00:00Z",
    "transactions" : [
      {
        "deposits" : [
          {
            "details" : {
              "fungible" : {
                "_0" : {
                  "amount" : {
                    "nominalAmount" : "10000"
                  },
                  "isXRD" : true
                }
              }
            },
            "resource" : {
              "atLedgerState" : {
                "epoch" : 61212,
                "version" : 91717878
              },
              "behaviors" : [
                {
                  "supplyFlexible" : {

                  }
                },
                {
                  "informationChangeable" : {

                  }
                }
              ],
              "divisibility" : 18,
              "metadata" : {
                "description" : "The Radix Public Network's native token, used to pay the network's required transaction fees and to secure the network through staking to its validator nodes.",
                "iconURL" : "https://assets.radixdlt.com/icons/icon-xrd-32x32.png",
                "name" : "Radix",
                "symbol" : "XRD",
                "tags" : [

                ]
              },
              "resourceAddress" : "resource_tdx_2_1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxtfd2jc",
              "totalSupply" : "1709169823456.654818219094302699"
            }
          }
        ],
        "depositSettingsUpdated" : false,
        "failed" : false,
        "id" : "txid_tdx_2_1hnf95et8tgd6s99lu6wy788ttcw7jjzz05szqsw5fv368pqnvwys4l0pgt",
        "manifestClass" : "General",
        "time" : "2023-12-13T09:23:16Z",
        "withdrawals" : [

        ]
      }
    ]
  }
]
"""

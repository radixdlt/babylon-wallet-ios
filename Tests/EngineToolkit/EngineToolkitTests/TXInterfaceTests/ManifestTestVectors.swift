import EngineToolkit
import EngineToolkitModels
import Foundation

public func manifestTestVectors() throws -> [(manifest: String, blobs: [[UInt8]])] {
	var testVectors: [(manifest: String, blobs: [[UInt8]])] = try [
		(
			manifest: String(decoding: resource(named: "access_rule", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		)
                ,
		(
			manifest: String(decoding: resource(named: "auth_zone", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "call_function", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "call_method", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "create_fungible_no_initial_supply", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "create_fungible_with_initial_supply", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "create_non_fungible_no_initial_supply", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "create_non_fungible_with_initial_supply", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "free_funds", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "mint_fungible", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "mint_non_fungible", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "multi_account_resource_transfer", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "new1", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "new2", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "new0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "publish", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "recall", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "resource_transfer", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "royalty", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "values", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
//		(
//			manifest: String(decoding: resource(named: "worktop", extension: ".rtm"), as: UTF8.self),
//			blobs: [[10]]
//		),
	]

        for (index, _) in testVectors.enumerated() {
                testVectors[index].manifest = try testVectors[index]
                        .manifest
                        .replacingOccurrences(
                                of: "${",
                                with: "{"
                        )
                        .replacingOccurrences(
                                of: "{xrd_resource_address}",
                                with: "resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs"
                        )
                        .replacingOccurrences(
                                of: "{faucet_component_address}",
                                with: "component_sim1pyh6hkm4emes653c38qgllau47rufnsj0qumeez85zyskzs0y9"
                        )
                        .replacingOccurrences(
                                of: "{account_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{this_account_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{account_component_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{other_account_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{account_a_component_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{account_b_component_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{account_c_component_address}",
                                with: "account_sim1q7qp88kspl8e4ay2jvqxln9r0kq3jy49akm3aue3jcaqnth6t3"
                        )
                        .replacingOccurrences(
                                of: "{owner_badge_resource_address}",
                                with: "resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs"
                        )
                        .replacingOccurrences(
                                of: "{minter_badge_resource_address}",
                                with: "resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs"
                        )
                        .replacingOccurrences(
                                of: "{auth_badge_resource_address}",
                                with: "resource_sim1q88e5v6nynxjnn2hr6pjm4ttvgwfctuall7yhnty7mrq30ccxs"
                        )
                        .replacingOccurrences(
                                of: "{mintable_resource_address}",
                                with: "resource_sim1qyqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqs6d89k"
                        )
                        .replacingOccurrences(
                                of: "{owner_badge_non_fungible_local_id}",
                                with: "#1#"
                        )
                        .replacingOccurrences(
                                of: "{auth_badge_non_fungible_local_id}",
                                with: "#1#"
                        )
                        .replacingOccurrences(
                                of: "{code_blob_hash}",
                                with: blake2b(data: Data([10])).hex
                        )
                        .replacingOccurrences(
                                of: "{schema_blob_hash}",
                                with: blake2b(data: Data([10])).hex
                        )
                        .replacingOccurrences(
                                of: "{initial_supply}",
                                with: "12"
                        )
                        .replacingOccurrences(
                                of: "{mint_amount}",
                                with: "12"
                        )
                        .replacingOccurrences(
                                of: "{non_fungible_local_id}",
                                with: "#1#"
                        )
        }

	return testVectors
}

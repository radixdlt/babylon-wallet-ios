import EngineToolkit
import EngineToolkitModels
import Foundation

public func manifestTestVectors() throws -> [(manifest: String, blobs: [[UInt8]])] {
	var testVectors: [(manifest: String, blobs: [[UInt8]])] = try [
		(
			manifest: String(decoding: resource(named: "new1", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "access_rule0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "analyze_manifest_sample", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "assert_access_rule0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "call_function0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "call_method0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "free_funds0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
//		( // FIXME:  Problem
//			manifest: String(decoding: resource(named: "metadata0", extension: ".rtm"), as: UTF8.self),
//			blobs: [[10]]
//		),
		(
			manifest: String(decoding: resource(named: "mint0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "mint1", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "multi_account_resource_transfer0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "new0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "new2", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "no_initial_supply0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "no_initial_supply1", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "publish0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		( // FIXME:  Problem
			manifest: String(decoding: resource(named: "recall0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "resource_transfer0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "royalty0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "values0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "with_initial_supply0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "with_initial_supply1", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		(
			manifest: String(decoding: resource(named: "worktop0", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
	]

	for (index, _) in testVectors.enumerated() {
		testVectors[index].manifest = try testVectors[index]
			.manifest
			.replacingOccurrences(of: "${", with: "{")
			.replacingOccurrences(of: "{xrd_resource_address}", with: "resource_sim1qzkcyv5dwq3r6kawy6pxpvcythx8rh8ntum6ws62p95sqjjpwr")
			.replacingOccurrences(of: "{faucet_component_address}", with: "component_sim1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7q8utaxr")
			.replacingOccurrences(of: "{this_account_component_address}", with: "account_sim1qwskd4q5jdywfw6f7jlwmcyp2xxq48uuwruc003x2kcskxh3na")
			.replacingOccurrences(of: "{account_component_address}", with: "account_sim1qwskd4q5jdywfw6f7jlwmcyp2xxq48uuwruc003x2kcskxh3na")
			.replacingOccurrences(of: "{other_account_component_address}", with: "account_sim1qdy4jqfpehf8nv4n7680cw0vhxqvhgh5lf3ae8jkjz6q5hmzed")
			.replacingOccurrences(of: "{account_a_component_address}", with: "account_sim1qwssydet6r0wen92wzs3nex8x9ch5ye0uz9tzgq5nchq86xmpm")
			.replacingOccurrences(of: "{account_b_component_address}", with: "account_sim1qdxpdrpjtsqmumccye045u4cfw2fqa3a9gujh6qvdresgnl2nh")
			.replacingOccurrences(of: "{account_c_component_address}", with: "account_sim1qd4jtjgqxtmk2m7ze0cpa6ugae8jwfhgxqenvw6m6uwqgqmp4q")
			.replacingOccurrences(of: "{owner_badge_resource_address}", with: "resource_sim1qrtkj5zx7tcpuhwjxerhhnmwv58k9v5yyjqgqt7rtnxsnqyl3s")
			.replacingOccurrences(of: "{minter_badge_resource_address}", with: "resource_sim1qp075qmn6389pkq30ppzzsuadd55ry04mjx69v86r4wq0feh02")
			.replacingOccurrences(of: "{auth_badge_resource_address}", with: "resource_sim1qp075qmn6389pkq30ppzzsuadd55ry04mjx69v86r4wq0feh02")
			.replacingOccurrences(of: "{mintable_resource_address}", with: "resource_sim1qqgvpz8q7ypeueqcv4qthsv7ezt8h9m3depmqqw7pc4sfmucfx")
			.replacingOccurrences(of: "{owner_badge_non_fungible_local_id}", with: "#1#")
			.replacingOccurrences(of: "{auth_badge_non_fungible_local_id}", with: "#1#")
			.replacingOccurrences(of: "{code_blob_hash}", with: blake2b(data: Data([10])).hex)
			.replacingOccurrences(of: "{schema_blob_hash}", with: blake2b(data: Data([10])).hex)
			.replacingOccurrences(of: "{initial_supply}", with: "12")
			.replacingOccurrences(of: "{mint_amount}", with: "12")
			.replacingOccurrences(of: "{non_fungible_local_id}", with: "#1#")
	}

	return testVectors
}

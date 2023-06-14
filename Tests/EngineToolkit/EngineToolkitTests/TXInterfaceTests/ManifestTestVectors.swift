import EngineToolkit
import Foundation

public func manifestTestVectors() throws -> [(manifest: String, blobs: [[UInt8]])] {
	var testVectors: [(manifest: String, blobs: [[UInt8]])] = try [
		(
			manifest: String(decoding: resource(named: "access_rule", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
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
			manifest: String(decoding: resource(named: "deposit_modes", extension: ".rtm"), as: UTF8.self),
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
			manifest: String(decoding: resource(named: "new0", extension: ".rtm"), as: UTF8.self),
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
			manifest: String(decoding: resource(named: "new3", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
		// TODO: This fails on RET side for some reason.
		//                (
		//                        manifest: String(decoding: resource(named: "publish", extension: ".rtm"), as: UTF8.self),
		//                        blobs: [[10]]
		//                ),
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
		(
			manifest: String(decoding: resource(named: "worktop", extension: ".rtm"), as: UTF8.self),
			blobs: [[10]]
		),
	]

	for (index, _) in testVectors.enumerated() {
		testVectors[index].manifest = try testVectors[index]
			.manifest
			.replacingOccurrences(of: "${",
			                      with: "{")
			.replacingOccurrences(of: "{xrd_resource_address}",
			                      with: "resource_sim1tknxxxxxxxxxradxrdxxxxxxxxx009923554798xxxxxxxxxakj8n3")
			.replacingOccurrences(of: "{fungible_resource_address}",
			                      with: "resource_sim1thvwu8dh6lk4y9mntemkvj25wllq8adq42skzufp4m8wxxuemugnez")
			.replacingOccurrences(of: "{resource_address}",
			                      with: "resource_sim1thvwu8dh6lk4y9mntemkvj25wllq8adq42skzufp4m8wxxuemugnez")
			.replacingOccurrences(of: "{gumball_resource_address}",
			                      with: "resource_sim1thvwu8dh6lk4y9mntemkvj25wllq8adq42skzufp4m8wxxuemugnez")
			.replacingOccurrences(of: "{non_fungible_resource_address}",
			                      with: "resource_sim1ngktvyeenvvqetnqwysevcx5fyvl6hqe36y3rkhdfdn6uzvt5366ha")
			.replacingOccurrences(of: "{badge_resource_address}",
			                      with: "resource_sim1ngktvyeenvvqetnqwysevcx5fyvl6hqe36y3rkhdfdn6uzvt5366ha")
			.replacingOccurrences(of: "{account_address}",
			                      with: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			.replacingOccurrences(of: "{this_account_address}",
			                      with: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			.replacingOccurrences(of: "{account_a_component_address}",
			                      with: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			.replacingOccurrences(of: "{account_b_component_address}",
			                      with: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			.replacingOccurrences(of: "{account_c_component_address}",
			                      with: "account_sim1cyvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cve475w0q")
			.replacingOccurrences(of: "{other_account_address}",
			                      with: "account_sim1cyzfj6p254jy6lhr237s7pcp8qqz6c8ahq9mn6nkdjxxxat5syrgz9")
			.replacingOccurrences(of: "{component_address}",
			                      with: "component_sim1cqvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvemygpmu")
			.replacingOccurrences(of: "{faucet_component_address}",
			                      with: "component_sim1cqvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvemygpmu")
			.replacingOccurrences(of: "{package_address}",
			                      with: "package_sim1p4r4955skdjq9swg8s5jguvcjvyj7tsxct87a9z6sw76cdfd2jg3zk")
			.replacingOccurrences(of: "{minter_badge_resource_address}",
			                      with: "resource_sim1ngktvyeenvvqetnqwysevcx5fyvl6hqe36y3rkhdfdn6uzvt5366ha")
			.replacingOccurrences(of: "{mintable_resource_address}",
			                      with: "resource_sim1nfhtg7ttszgjwysfglx8jcjtvv8q02fg9s2y6qpnvtw5jsy3wvlhj6")
			.replacingOccurrences(of: "{mintable_fungible_resource_address}",
			                      with: "resource_sim1nfhtg7ttszgjwysfglx8jcjtvv8q02fg9s2y6qpnvtw5jsy3wvlhj6")
			.replacingOccurrences(of: "{second_resource_address}",
			                      with: "resource_sim1nfhtg7ttszgjwysfglx8jcjtvv8q02fg9s2y6qpnvtw5jsy3wvlhj6")
			.replacingOccurrences(of: "{mintable_non_fungible_resource_address}",
			                      with: "resource_sim1nfhtg7ttszgjwysfglx8jcjtvv8q02fg9s2y6qpnvtw5jsy3wvlhj6")
			.replacingOccurrences(of: "{vault_address}",
			                      with: "internal_vault_sim1tqvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvevp72ff")
			.replacingOccurrences(of: "{owner_badge_non_fungible_local_id}", with: "#1#")
			.replacingOccurrences(of: "{code_blob_hash}",
			                      with: "5b4b01a4a3892ea3751793da57f072ae08eec694ddcda872239fc8239e4bcd1b")
			.replacingOccurrences(of: "{initial_supply}", with: "12")
			.replacingOccurrences(of: "{mint_amount}", with: "12")
			.replacingOccurrences(of: "{non_fungible_local_id}", with: "#12#")
			.replacingOccurrences(of: "{auth_badge_resource_address}",
			                      with: "resource_sim1n24hvnrgmhj6j8dpjuu85vfsagdjafcl5x4ewc9yh436jh2hpu4qdj")
			.replacingOccurrences(of: "{auth_badge_non_fungible_local_id}", with: "#1#")
			.replacingOccurrences(of: "{package_address}",
			                      with: "package_sim1p4r4955skdjq9swg8s5jguvcjvyj7tsxct87a9z6sw76cdfd2jg3zk")
			.replacingOccurrences(of: "{consensusmanager_address}",
			                      with: "consensusmanager_sim1scxxxxxxxxxxcnsmgrxxxxxxxxx000999665565xxxxxxxxxxc06cl")
			.replacingOccurrences(of: "{clock_address}",
			                      with: "clock_sim1skxxxxxxxxxxclckxxxxxxxxxxx002253583992xxxxxxxxxx58hk6")
			.replacingOccurrences(of: "{validator_address}",
			                      with: "validator_sim1sgvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvedzgr3l")
			.replacingOccurrences(of: "{accesscontroller_address}",
			                      with: "accesscontroller_sim1cvvgx33089ukm2pl97pv4max0x40ruvfy4lt60yvya744cvexaj7at")
	}

	return testVectors
}

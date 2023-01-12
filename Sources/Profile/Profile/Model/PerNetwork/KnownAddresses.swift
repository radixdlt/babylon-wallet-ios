import Cryptography
import EngineToolkit
import Prelude

// MARK: - Network.KnownAddresses
public extension Network {
	struct KnownAddresses: Sendable, Hashable {
		public let faucet: ComponentAddress

		/// For creation of On-Ledger accounts (non-virtual)
		public let createAccountComponent: PackageAddress

		public let xrd: ResourceAddress

		public init(faucet: ComponentAddress, createAccountComponent: PackageAddress, xrd: ResourceAddress) {
			self.faucet = faucet
			self.createAccountComponent = createAccountComponent
			self.xrd = xrd
		}
	}
}

public extension Network.KnownAddresses {
	static let addressMap: [NetworkID: Network.KnownAddresses] = [
		.nebunet: .nebunet,
		.gilganet: .gilganet,
		.enkinet: .enkinet,
		.hammunet: .hammunet,
		.mardunet: .mardunet,
	]

	static let nebunet = Self(
		faucet: "component_tdx_b_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qdxyth4",
		createAccountComponent: "package_tdx_b_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlssf7lg2",
		xrd: "resource_tdx_b_1qzkcyv5dwq3r6kawy6pxpvcythx8rh8ntum6ws62p95s9hhz9x"
	)

	static let gilganet = Self(
		faucet: "component_tdx_20_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlnye7x",
		createAccountComponent: "package_tdx_20_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlskx38d7",
		xrd: "resource_tdx_20_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfgndge"
	)

	static let enkinet = Self(
		faucet: "component_tdx_21_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlrqh7e",
		createAccountComponent: "package_tdx_21_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlskk4fdp",
		xrd: "resource_tdx_21_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfchrgx"
	)

	static let hammunet = Self(
		faucet: "component_tdx_22_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7ql6v973",
		createAccountComponent: "package_tdx_22_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk0emdf",
		xrd: "resource_tdx_22_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqfpm3gw"
	)
	static let mardunet = Self(
		faucet: "component_tdx_24_1qftacppvmr9ezmekxqpq58en0nk954x0a7jv2zz0hc7qlp5g7p",
		createAccountComponent: "package_tdx_24_1qy4hrp8a9apxldp5cazvxgwdj80cxad4u8cpkaqqnhlsk5pkde",
		xrd: "resource_tdx_24_1qzxcrac59cy2v9lpcpmf82qel3cjj25v3k5m09rxurgqf6rug7"
	)
}

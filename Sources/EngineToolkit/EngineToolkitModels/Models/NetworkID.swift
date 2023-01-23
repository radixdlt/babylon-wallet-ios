import Prelude

// MARK: - NetworkIDType
// TODO: move this type to Network.swift.
//
// public typealias NetworkID = Network.ID // or even deprecate it?
//
// ```
// public struct Network {
//     public typealias ID = Tagged<(Self, id: ()), UInt8>
// }
// ```
//
// Probably best to do when we move all models into a single package.

public typealias NetworkID = Tagged<(network: (), id: ()), UInt8>

public extension NetworkID {
	/// Public Facing Permanent Networks (0x00 - 0x09)
	// - mainnet
	// - stokenet

	/// Mainnet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L77
	/// Decimal value: 01
	static let mainnet: Self = 0x01

	/// Stokenet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L78
	/// Decimal value: 02
	static let stokenet: Self = 0x02

	/// Babylon Temporary Testnets (0x0a - 0x0f)
	// - adapanet = Babylon Alphanet, after Adapa
	// - nebunet = Babylon Betanet, after Nebuchadnezzar

	/// Adapanet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L83
	/// Decimal value: 10
	static let adapanet: Self = 0x0A

	/// Nebunet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L84
	/// Decimal value: 11
	static let nebunet: Self = 0x0B

	/// RDX Development - Semi-permanent Testnets (start with 0x2)
	// - gilganet = Integration, after Gilgamesh
	// - enkinet = Misc Network 1, after Enki / Enkidu
	// - hammunet = Misc Network 2, after Hammurabi
	// - nergalnet = A Network for DevOps testing, after the Mesopotamian god Nergal
	// - mardunet = A staging Network for testing new releases to the primary public environment,
	//              after the Babylonian god Marduk

	/// Gilganet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L
	/// Decimal value: 32
	static let gilganet: Self = 0x20

	/// Enkinet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L94
	/// Decimal value: 33
	static let enkinet: Self = 0x21

	/// Hammunet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L95
	/// Decimal value: 34
	static let hammunet: Self = 0x22

	/// Nergalnet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L96
	/// Decimal value: 35
	static let nergalnet: Self = 0x23

	/// Mardunet
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L97
	/// Decimal value: 36
	static let mardunet: Self = 0x24

	/// Ephemeral Networks (start with 0xF)
	// - localnet = The network used when running locally in development
	// - inttestnet = The network used when running integration tests

	/// Local Simulator
	/// https://github.com/radixdlt/babylon-node/blob/main/common/src/main/java/com/radixdlt/networks/Network.java#L104
	/// Decimal value: 242
	static let simulator: Self = 0xF2
}

public extension NetworkID {
	typealias AllCases = [Self]

	static var allCases: [NetworkID] {
		[.mainnet, .stokenet, .adapanet, .nebunet, .gilganet, .enkinet, .hammunet, .nergalnet, .mardunet, .simulator]
	}

	static func all(but excluded: NetworkID) -> AllCases {
		var allBut = Self.allCases
		allBut.removeAll(where: { $0 == excluded })
		return allBut
	}
}

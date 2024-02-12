public typealias NetworkID = Tagged<(network: (), id: ()), UInt8>

extension NetworkID {
	public static let mainnet: Self = 0x01
	public static let stokenet: Self = 0x02
	public static let adapanet: Self = 0x0A
	public static let nebunet: Self = 0x0B
	public static let kisharnet: Self = 0x0C
	public static let ansharnet: Self = 0x0D
	public static let zabanet: Self = 0x0E
	public static let gilganet: Self = 0x20
	public static let enkinet: Self = 0x21
	public static let hammunet: Self = 0x22
	public static let nergalnet: Self = 0x23
	public static let mardunet: Self = 0x24
	public static let simulator: Self = 0xF2
}

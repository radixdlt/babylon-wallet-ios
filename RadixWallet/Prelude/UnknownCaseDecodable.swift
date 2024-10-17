// MARK: - UnknownCaseDecodable
protocol UnknownCaseDecodable: Decodable where Self: RawRepresentable {
	static var unknown: Self { get }
}

extension UnknownCaseDecodable where RawValue: Decodable {
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(RawValue.self)
		self = .init(rawValue: rawValue) ?? Self.unknown
	}
}

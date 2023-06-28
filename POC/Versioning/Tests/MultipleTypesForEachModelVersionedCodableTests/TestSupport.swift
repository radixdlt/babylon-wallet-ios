import CustomDump
import TestUtils
import VersionedCodable

public func XCTAssertJSONEncoding<T: VersionedCodable>(
	versioned versionedEncodable: @autoclosure () throws -> T,
	_ json: @autoclosure () throws -> JSON,
	encoder: JSONEncoder = XCTAssertJSON.configuration.encoder,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #filePath,
	line: UInt = #line
) throws where T: Encodable {
	let sut = try JSON(data: encoder.encode(versioned: versionedEncodable()))
	let json = try json()
	XCTAssertNoDifference(sut, json, message(), file: file, line: line)
}

public func XCTAssertJSONDecoding<T: VersionedCodable>(
	versioned json: @autoclosure () throws -> JSON,
	_ decodable: @autoclosure () throws -> T,
	decoder: JSONDecoder = XCTAssertJSON.configuration.decoder,
	_ message: @autoclosure () -> String = "",
	file: StaticString = #filePath,
	line: UInt = #line
) throws where T: Decodable, T: Equatable {
	let sut = try decoder.decode(versioned: T.self, from: json().data)
	let decodable = try decodable()
	XCTAssertNoDifference(sut, decodable, message(), file: file, line: line)
}

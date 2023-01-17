//
// CodableHelper.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import ClientPrelude

open class CodableHelper {
	private static var customDateFormatter: DateFormatter?
	private static var defaultDateFormatter: DateFormatter = OpenISO8601DateFormatter()

	private static var customJSONDecoder: JSONDecoder?
	private static var defaultJSONDecoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .formatted(CodableHelper.dateFormatter)
		return decoder
	}()

	private static var customJSONEncoder: JSONEncoder?
	private static var defaultJSONEncoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .formatted(CodableHelper.dateFormatter)
		encoder.outputFormatting = .prettyPrinted
		return encoder
	}()

	public static var dateFormatter: DateFormatter {
		get { customDateFormatter ?? defaultDateFormatter }
		set { customDateFormatter = newValue }
	}

	public static var jsonDecoder: JSONDecoder {
		get { customJSONDecoder ?? defaultJSONDecoder }
		set { customJSONDecoder = newValue }
	}

	public static var jsonEncoder: JSONEncoder {
		get { customJSONEncoder ?? defaultJSONEncoder }
		set { customJSONEncoder = newValue }
	}

	open class func decode<T>(_ type: T.Type, from data: Data) -> Swift.Result<T, Error> where T: Decodable {
		Swift.Result { try jsonDecoder.decode(type, from: data) }
	}

	open class func encode<T>(_ value: T) -> Swift.Result<Data, Error> where T: Encodable {
		Swift.Result { try jsonEncoder.encode(value) }
	}
}

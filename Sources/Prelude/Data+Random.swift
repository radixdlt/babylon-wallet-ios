import Foundation

#if DEBUG
struct RandomizeDataError: Swift.Error {}
extension Data {
	public static func random(byteCount: Int) throws -> Self {
		var bytes = [UInt8](repeating: 0, count: byteCount)
		let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
		guard status == errSecSuccess else {
			throw RandomizeDataError()
		}
		return Data(bytes)
	}
}
#endif

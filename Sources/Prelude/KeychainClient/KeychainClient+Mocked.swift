#if DEBUG
import Dependencies

public extension KeychainClient {
	static var testValue = Self(
		dataForKey: unimplemented("\(Self.self).dataForKey"),
		removeDataForKey: unimplemented("\(Self.self).removeDataForKey"),
		setDataForKey: unimplemented("\(Self.self).setDataForKey"),
		updateDataForKey: unimplemented("\(Self.self).updateDataForKey")
	)

	static var previewValue = Self(
		dataForKey: { _, _ in Data([0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF]) },
		removeDataForKey: { _ in },
		setDataForKey: { _, _, _ in },
		updateDataForKey: { _, _, _, _ in }
	)
}
#endif

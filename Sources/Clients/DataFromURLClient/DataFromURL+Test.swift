import Dependencies
import Foundation
import XCTestDynamicOverlay

public extension DependencyValues {
	var data: ReadDataEffect {
		get { self[ReadDataEffect.self] }
		set { self[ReadDataEffect.self] = newValue }
	}
}

extension ReadDataEffect: TestDependencyKey {
	public static let previewValue = Self(
		dataFromURL: { _, _ in Data() }
	)

	public static let testValue = Self(
		dataFromURL: unimplemented("\(Self.self).dataFromURL")
	)
}

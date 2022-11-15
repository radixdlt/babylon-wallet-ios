import Dependencies
import Foundation
import XCTestDynamicOverlay

public extension DependencyValues {
	var errorQueue: ErrorQueue {
		get { self[ErrorQueue.self] }
		set { self[ErrorQueue.self] = newValue }
	}
}

// MARK: - ErrorQueue + TestDependencyKey
extension ErrorQueue: TestDependencyKey {
	public static let previewValue = Self(
		schedule: { _ in }
	)
	public static let testValue = Self(
		schedule: unimplemented("\(Self.self).schedule")
	)
}

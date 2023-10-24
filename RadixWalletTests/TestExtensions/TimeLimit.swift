//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for Swift project authors
//
import XCTest

// MARK: - TimeLimit
// From swift-testing:
// https://github.com/apple/swift-testing/blob/1afab676568b1f633190c3cbbaa3e0ad1961d4b5/Sources/Testing/Traits/TimeLimitTrait.swift#L112-L147

// MODIFICATIONS:
// * Change `swift-testing`.Test.Clock to `ContinuousClock` (should we use `SuspendingClock` instead?)
// * Change `timeLimit` to be an enum
// * Made `timeoutHandler` optional, defaulting to nil
// * Added `function` / `file` / `line`
// * After timeout handler I've added a `XCTFail`

/// RawValue is measured in milliseconds (must of course not be power's of two... just I like them!)
public enum TimeLimit: Sendable, Hashable {
	case preset(Preset)
	case custom(Duration)
	public enum Preset: Int, Sendable, Hashable {
		case fast = 256
		case normal = 1024
		case slow = 2048
		case marathon = 16384
		var duration: Duration {
			.milliseconds(rawValue)
		}
	}

	public static let `default`: Self = .fast
	public static let fast: Self = .preset(.fast)
	public static let normal: Self = .preset(.normal)
	public static let slow: Self = .preset(.slow)
	public static let marathon: Self = .preset(.marathon)

	var duration: Duration {
		switch self {
		case let .preset(preset): preset.duration
		case let .custom(duration): duration
		}
	}
}

/// Invoke a function with a timeout.
///
/// - Parameters:
///   - timeLimit: The amount of time until the closure times out.
///   - body: The function to invoke.
///   - timeoutHandler: An optional function to invoke if `body` times out.
///
/// - Throws: Any error thrown by `body`.
///
/// If `body` does not return or throw before `timeLimit` is reached,
/// `timeoutHandler` is called and given the opportunity to handle the timeout
/// and `body` is cancelled.
///
/// This function is not part of the public interface of the testing library.
func withTimeLimit(
	_ timeLimit: TimeLimit = .default,
	failOnTimeout: Bool = true,
	_ body: @escaping @Sendable () async throws -> Void,
	timeoutHandler: (@Sendable () -> Void)? = nil,
	function: StaticString = #function, file: StaticString = #file, line: UInt = #line
) async throws {
	try await withThrowingTaskGroup(of: Void.self) { group in
		group.addTask {
			// If sleep() returns instead of throwing a CancellationError, that means
			// the timeout was reached before this task could be cancelled, so call
			// the timeout handler.
			try await ContinuousClock().sleep(for: timeLimit.duration)
			timeoutHandler?()
			if failOnTimeout {
				XCTFail("Test '\(function)' timed out after \(timeLimit.duration). Specify `withTimeLimit(failOnTimeout: false)` if you want lenient testing, or increase the timeout.", file: file, line: line)
			}
		}
		group.addTask(operation: body)

		defer {
			group.cancelAll()
		}
		try await group.next()!
	}
}

extension XCTestCase {
	func nearFutureFulfillment(
		of expectation: XCTestExpectation,
		limit timelimit: TimeLimit = .default,
		enforceOrder: Bool = false
	) async {
		await nearFutureFulfillment(of: [expectation], limit: timelimit, enforceOrder: enforceOrder)
	}

	func nearFutureFulfillment(
		of expectations: [XCTestExpectation],
		limit timelimit: TimeLimit = .default,
		enforceOrder: Bool = false
	) async {
		let timeout = timelimit.duration.timeInterval
		await fulfillment(of: expectations, timeout: timeout, enforceOrder: enforceOrder)
	}
}

extension Duration {
	/// Possibly lossy conversion to TimeInterval
	var timeInterval: TimeInterval {
		TimeInterval(components.seconds) + Double(components.attoseconds) / 1e18
	}
}

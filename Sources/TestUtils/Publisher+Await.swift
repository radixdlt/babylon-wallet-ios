//
//  File.swift
//
//
//  Created by Alexander Cyon on 2022-06-30.
//

import Combine
import Foundation
import XCTest

// Author: John Sundell
// blog post: https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
// Modification; fixed crash: waitForExpectations "must be called on the main thread"
// by marking method with `@MainActor`
public extension XCTestCase {
	@MainActor
	func output<T: Publisher>(
		from publisher: T,
		timeout: TimeInterval = 1,
		file: StaticString = #file,
		line: UInt = #line
	) throws -> T.Output {
		var result: Result<T.Output, Error>?
		let expectation = expectation(description: "Awaiting Output from Publisher")

		let cancellable = publisher.sink(
			receiveCompletion: { completion in
				switch completion {
				case let .failure(error):
					result = .failure(error)
				case .finished:
					break
				}

				expectation.fulfill()
			},
			receiveValue: { value in
				result = .success(value)
			}
		)

		waitForExpectations(timeout: timeout)
		cancellable.cancel()

		let unwrappedResult = try XCTUnwrap(
			result,
			"Awaited publisher did not produce any output",
			file: file,
			line: line
		)

		return try unwrappedResult.get()
	}

	@discardableResult
	@MainActor
	func completion<T: Publisher>(
		of publisher: @autoclosure () -> T,
		timeout: TimeInterval = 1,
		file: StaticString = #file,
		line: UInt = #line
	) throws -> Subscribers.Completion<T.Failure> {
		var completion: Subscribers.Completion<T.Failure>?
		let expectation = expectation(description: "Awaiting Completion of Publisher")

		let cancellable = publisher().sink(
			receiveCompletion: { _completion in
				completion = _completion
				expectation.fulfill()
			},
			receiveValue: { _ in
				// We do not care about values.
			}
		)

		waitForExpectations(timeout: timeout)
		cancellable.cancel()

		let unwrappedResult = try XCTUnwrap(
			completion,
			"Awaited publisher did not complete.",
			file: file,
			line: line
		)

		return unwrappedResult
	}
}

import Prelude
import XCTest

// MARK: - ValidationTests
final class ValidationTests: XCTestCase {
	func testPropertyWrapper() {
		struct InputState {
			@Validation<String, String> var name: String?

			init(initialName: String?) {
				self._name = .init(
					wrappedValue: initialName,
					onNil: "Name cannot be nil",
					rules: [
						.if(\.isBlank, error: "Name cannot be blank"),
						.unless({ $0.count >= 2 }, error: "Name cannot be shorter than 2 characters"),
						.if({ $0.rangeOfCharacter(from: .symbols) != nil }, error: "Name cannot contain special characters or symbols"),
					]
				)
			}
		}

		var sut = InputState(initialName: nil)
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray("Name cannot be nil"))

		sut.name = ""
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot be blank",
			"Name cannot be shorter than 2 characters"
		))

		sut.name = "D"
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot be shorter than 2 characters"
		))

		sut.name = "Da"
		XCTAssertEqual(sut.name, "Da")
		XCTAssertNil(sut.$name.errors)

		sut.name = "David"
		XCTAssertEqual(sut.name, "David")
		XCTAssertNil(sut.$name.errors)

		sut.name = "David$"
		XCTAssertNil(sut.name)
		XCTAssertEqual(sut.$name.errors, NonEmptyArray(
			"Name cannot contain special characters or symbols"
		))
	}
}

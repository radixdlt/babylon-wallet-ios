import FeaturePrelude
import XCTest

final class ValidationExtraTests: XCTestCase {
	func testBinding() {
		var validation = Validation<String, String>(
			wrappedValue: nil,
			onNil: "Cannot be nil",
			rules: [
				.if(\.isEmpty, error: "Cannot be empty"),
				.if(\.isBlank, error: "Cannot be blank"),
			]
		)
		let sut = Binding<String>.validation(
			Binding(
				get: { validation },
				set: { validation = $0 }
			)
		)
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be nil"))

		sut.wrappedValue = ""
		XCTAssertEqual(sut.wrappedValue, "")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be empty", "Cannot be blank"))

		sut.wrappedValue = " "
		XCTAssertEqual(sut.wrappedValue, " ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))

		sut.wrappedValue = "  "
		XCTAssertEqual(sut.wrappedValue, "  ")
		XCTAssertEqual(validation.errors, NonEmptyArray("Cannot be blank"))
	}
}

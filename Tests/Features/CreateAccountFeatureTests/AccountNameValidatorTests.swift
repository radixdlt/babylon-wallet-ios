@testable import CreateAccountFeature
import Dependencies
import TestUtils

final class AccountNameValidatorTests: TestCase {
	private var sut: AccountNameValidator!

	override func setUpWithError() throws {
		try super.setUpWithError()
		sut = AccountNameValidator.liveValue
	}

	override func tearDownWithError() throws {
		sut = nil
		try super.tearDownWithError()
	}

	func test_validate_whenAccountNameContainsWhitespacesOnEnds_thenTrimWhitespaces() {
		// given
		let accountName = "   Test Account      "
		let expectedAccountName = "Test Account"

		// when
		let result = sut.validate(accountName)

		// then
		XCTAssertTrue(result.isValid)
		XCTAssertEqual(result.trimmedName, expectedAccountName)
	}

	func test_validate_whenAccountNameHasZeroCharacters_thenAccountNameIsNotValid() {
		// given
		let accountName = ""
		let expectedAccountName = ""

		// when
		let result = sut.validate(accountName)

		// then
		XCTAssertFalse(result.isValid)
		XCTAssertEqual(result.trimmedName, expectedAccountName)
	}

	func test_validate_whenAccountNameIsOverMaximumCharacterLimit_thenAccountNameIsNotValid() {
		// given
		let accountName = "This is one very log name for an account"
		let expectedAccountName = "This is one very log name for an account"

		// when
		let result = sut.validate(accountName)

		// then
		XCTAssertFalse(result.isValid)
		XCTAssertEqual(result.trimmedName, expectedAccountName)
	}

	func test_isCharacterCountOverLimit_withValidAccountName() {
		// given
		let accountName = "This is short name"

		// when
		let isOverLimit = sut.isCharacterCountOverLimit(accountName)

		// then
		XCTAssertFalse(isOverLimit)
	}

	func test_isCharacterCountOverLimit_withInvalidAccountName() {
		// given
		let accountName = "This is one very log name for an account"

		// when
		let isOverLimit = sut.isCharacterCountOverLimit(accountName)

		// then
		XCTAssertTrue(isOverLimit)
	}
}

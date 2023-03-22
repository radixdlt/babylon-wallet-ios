import Prelude
import XCTest

final class SortedTests: XCTestCase {
	struct Person: Equatable, Identifiable {
		enum Number: Equatable, Comparable {
			case one, two, three, four, five
		}

		let id: String
		let number: Number
	}

	let michael = Person(id: "Michael", number: .one)
	let sarah = Person(id: "Sarah", number: .two)
	let tyler = Person(id: "Tyler", number: .three)
	let jack = Person(id: "Jack", number: .four)
	let mary = Person(id: "Mary", number: .five)

	func testPropertyWrapper() {
		struct Group {
			@Sorted(by: \.number)
			var people: IdentifiedArrayOf<Person> = []
		}

		var group = Group(people: [tyler, michael, sarah])
		XCTAssertNotEqual(group.people, [tyler, michael, sarah])
		XCTAssertEqual(group.people, [michael, sarah, tyler])

		group.people.append(contentsOf: [mary, jack])
		XCTAssertNotEqual(group.people, [tyler, michael, sarah, mary, jack])
		XCTAssertEqual(group.people, [michael, sarah, tyler, jack, mary])

		group.people[id: "Sarah"] = nil
		group.people[id: "Tyler"] = nil
		XCTAssertNotEqual(group.people, [michael, mary, jack])
		XCTAssertEqual(group.people, [michael, jack, mary])
	}
}

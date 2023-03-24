import Prelude
import XCTest

final class SortedTests: XCTestCase {
	struct Person: Equatable, Identifiable {
		enum Number: Equatable, Comparable {
			case one, two, three, four, five
		}

		var id: String { String(name.hashValue) }
		let name: String
		let number: Number
	}

	let michael = Person(name: "Michael", number: .one)
	let sarah = Person(name: "Sarah", number: .two)
	let tyler = Person(name: "Tyler", number: .three)
	let jack = Person(name: "Jack", number: .four)
	let mary = Person(name: "Mary", number: .five)

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

		group.people[id: sarah.id] = nil
		group.people[id: tyler.id] = nil
		XCTAssertNotEqual(group.people, [michael, mary, jack])
		XCTAssertEqual(group.people, [michael, jack, mary])
	}
}

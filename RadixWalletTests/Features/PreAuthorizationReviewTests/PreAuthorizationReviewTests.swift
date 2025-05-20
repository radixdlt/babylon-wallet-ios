@testable import Radix_Wallet_Dev
import Testing

struct PreAuthorizationReviewTests {
	@Test func timeFormatter() async throws {
		func verify(_ seconds: Int, _ expected: String) {
			let result = PreAuthorizationReview.TimeFormatter.format(seconds: seconds)
			#expect(result == expected)
		}
		let minute = 60
		let hour = 60 * minute
		let day = 24 * hour
		let values: [Int: String] = [
			1: "1 second",
			34: "34 seconds",
			minute + 23: "1 minute",
			56 * minute + 2: "56 minutes",
			hour + 24 * minute: "1:24 hour",
			23 * hour + 21 * minute: "23:21 hours",
			day: "1 day",
			8 * day: "8 days",
		]
		for item in values {
			verify(item.key, item.value)
		}
	}
}

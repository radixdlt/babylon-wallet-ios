extension PreAuthorizationReview {
	/// Given an amount of seconds, returns a formatted String using the corresponding unit (days/hours/minutes/seconds).
	/// A few examples on how should it look for each of them:
	/// - `8 days` / `1 day`
	/// - `23:21 hours` / `1:24 hour`
	/// - `56 minutes` / `1 minute`
	/// - `34 seconds` / `1 second`
	enum TimeFormatter {
		static func format(seconds: Int) -> String {
			typealias S = L10n.PreAuthorizationReview.TimeFormat
			let minutes = seconds / 60
			let hours = minutes / 60
			let days = hours / 24
			if days > 0 {
				return days == 1 ? S.day : S.days(days)
			} else if hours > 0 {
				let remainingMinutes = minutes % 60
				let formatted = String(format: "%d:%02d", hours, remainingMinutes)
				return hours == 1 ? S.hour(formatted) : S.hours(formatted)
			} else if minutes > 0 {
				let formatted = "\(minutes)"
				return minutes == 1 ? S.minute(formatted) : S.minutes(formatted)
			} else {
				return seconds == 1 ? S.second : S.seconds(seconds)
			}
		}
	}
}

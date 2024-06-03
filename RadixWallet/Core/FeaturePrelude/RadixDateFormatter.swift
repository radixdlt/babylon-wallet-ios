import Foundation

// MARK: - RadixDateFormatter
public enum RadixDateFormatter {
	public static func string(from date: Date) -> String {
		let dateString = { date.formatted(date: .abbreviated, time: .omitted) }

		let calendar = Calendar.current

		if calendar.isDateInTomorrow(date) {
			return L10n.TimeFormatting.tomorrow
		} else if calendar.isDateInToday(date) {
			let timeInterval = date.timeIntervalSinceNow
			if timeInterval > 0 {
				return L10n.TimeFormatting.today
			} else if timeInterval > -60 {
				return L10n.TimeFormatting.justNow
			} else {
				guard let relative = relativeFormatter.string(from: -timeInterval) else {
					return dateString() // This should never happen
				}
				return L10n.TimeFormatting.ago(relative)
			}
		} else if calendar.isDateInYesterday(date) {
			return L10n.TimeFormatting.yesterday
		} else {
			return dateString()
		}
	}

	private static let relativeFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .short
		formatter.allowedUnits = [.minute, .hour, .day, .month, .year]
		formatter.zeroFormattingBehavior = .dropAll
		formatter.maximumUnitCount = 1
		return formatter
	}()
}

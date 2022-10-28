import Dependencies

// MARK: - AccountNameValidator + DependencyKey
extension AccountNameValidator: DependencyKey {
	public static let liveValue: Self = {
		let minimumCharCount = 1
		let maximumCharCount = 20

		let isCharacterCountOverLimit: IsCharacterCountOverLimit = { name in
			name.count > maximumCharCount
		}

		return Self(
			validate: { name in
				let trimmedName = name.trimmed()
				let isValid = trimmedName.count >= minimumCharCount && !isCharacterCountOverLimit(trimmedName)
				return (isValid, trimmedName)
			},
			isCharacterCountOverLimit: isCharacterCountOverLimit
		)
	}()
}

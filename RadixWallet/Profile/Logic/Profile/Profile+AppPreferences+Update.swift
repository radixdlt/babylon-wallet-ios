

extension AppPreferences {
	public mutating func updateDisplay(_ display: Display) {
		self.display = display
	}
}

extension Profile {
	public mutating func updateDisplayAppPreferences(_ display: AppPreferences.Display) {
		self.appPreferences.updateDisplay(display)
	}
}

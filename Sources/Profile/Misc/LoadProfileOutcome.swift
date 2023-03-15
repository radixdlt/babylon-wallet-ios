

public enum LoadProfileOutcome: Sendable, Hashable {
	case newUser
	case usersExistingProfileCouldNotBeLoaded(failure: Profile.LoadingFailure)
	case existingProfileLoaded
}

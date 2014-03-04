def viewDidLoad
  super

  Motion.wiretap(self.loginButton, :enabled).bind_to(
    Motion.wiretap([
      Motion.wiretap(self.usernameTextField, :text),
      Motion.wiretap(self.passwordTextField, :text),
      Motion.wiretap(LoginManager.sharedManager, :loggingIn),
      Motion.wiretap(self, :loggedIn),
    ]).combine do |username, password, logging_in, logged_in|
      return false unless username.length > 0
      return false unless password.length > 0
      return false if logging_in || logged_in
    end
    )

  # this is the "polluting" syntax for creating a wiretap
  self.loginButton.wiretap.on(:touch) do
    -> {
      LoginManager.sharedManager.logInWithUsername(
        self.usernameTextField.text,
        password: self.passwordTextField.text)
    }.wiretap.on_error do |error|
      presentError(error)
    end.and_then do
      loggedIn = true
    end
  end
end



# Here's another way to create a wiretap, using the MW() method.
MW(self, :name) do |new_name|
  puts "Name changed to #{new_name}"
end


name_is_valid_signal = MW([
  MW(usernameField, :text),
  MW(passwordField, :text),
])# an array of signals fires whenever any element fires.
  # combined signals transform a list of values into one.
  .combine do |username, password|
    return username.present? && password.present? && ! username.include? ' '
  end

loginButton.wiretap(:enabled).bind_to(name_is_valid_signal)


executing = MotionWiretap::Signal.new(true)
not_processing = executing.map { |val| ! val }
field_text_color = executing.map do |val|
  val ? UIColor.lightGrayColor : UIColor.blackColor
end

MW(self.firstNameField, :textColor).bind_to(field_text_color)
MW(self.lastNameField, :textColor).bind_to(field_text_color)
MW(self.emailField, :textColor).bind_to(field_text_color)
MW(self.reEmailField, :textColor).bind_to(field_text_color)

MW(self.firstNameField, :enabled).bind_to(not_processing)
MW(self.lastNameField, :enabled).bind_to(not_processing)
MW(self.emailField, :enabled).bind_to(not_processing)
MW(self.reEmailField, :enabled).bind_to(not_processing)




textField.wiretap(:text).bind_to(viewModel.wiretap(:title))
scoreStepper.wiretap(:value).take(viewModel.maxPointUpdates) do |points|
  viewModel.points = points
end

MW(uploadButton)      # returns a WiretapView
  .on(:touch)         # which can respond to gesture recognizers
  .skip(KMaxUploads - 1)
  .take(1) do
    nameField.enabled = false
    scoreStepper.hidden = true
    uploadButton.hidden = true
end



[
  self.wiretap(:password),
  self.wiretap(:passwordConfirmation),
].wiretap.combine do |password, password_confirmation|
  return password == password_confirmation
end.and_then do |passwords_match|
  self.createEnabled = passwords_match
end



helpLabel.wiretap(:text).bind_to(
  self.wiretap(:help)
    # filtered signals only fire when the block returns true
    .filter { |new_help| !new_help.nil? }
    .map { |new_help| new_help.upcase }
    )






[
  client.fetchUserRepos,  # returns a wiretap
  client.fetchOrgRepos,  # returns a wiretap
].wiretap.and_then do
  puts "They're both done!"
end




client.loginUser  # return wiretap
  .and_then(client.loadCachedMessages)
  .and_then(client.fetchMessages)
  .and_then do
    puts "Fetched all messages"
end








-> {
  fetchUserWithUsername('colinta')
}.wiretap  # returns WiretapProc
  .queue(Dispatch::Queue.concurrent)  # the Proc will be run on this queue
  .map do |user|
    NSImage.alloc.initWithContentsOfURL(user.avatarURL)
  end
  .deliver_on(Dispatch::Queue.main)  # returns a signal that will be called on the main queue
  .and_then do |image|
    imageView.image = image
  end


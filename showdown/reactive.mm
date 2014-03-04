- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self);

    RAC(self.loginButton, enabled) = [RACSignal
        combineLatest:@[
            self.usernameTextField.rac_textSignal,
            self.passwordTextField.rac_textSignal,
            RACAbleWithStart(LoginManager.sharedManager, loggingIn),
            RACAbleWithStart(self.loggedIn)
        ] reduce:^(NSString *username, NSString *password, NSNumber *loggingIn, NSNumber *loggedIn) {
            return @(username.length > 0 && password.length > 0 && !loggingIn.boolValue && !loggedIn.boolValue);
        }];

    [[self.loginButton rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(UIButton *sender) {
        @strongify(self);

        RACSignal *loginSignal = [[LoginManager sharedManager]
            logInWithUsername:self.usernameTextField.text
            password:self.passwordTextField.text];

        [loginSignal subscribeError:^(NSError *error) {
            @strongify(self);
            [self presentError:error];
        } completed:{
            @strongify(self);
            self.loggedIn = YES;
        }];
    }];
}


[RACAble(self.name) subscribeNext:^(NSString *newName){
    NSLog(@"Name changed to %@",newName);
}];


NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
RACSignal *nameFieldValid = [RACSignal combineLatest:@[ self.usernameField.rac_textSignal, self.passwordField.rac_textSignal ]
 reduce:^(NSString *username, NSString *password) {
    return @((username.length > 0) && (password.length > 0) &&
            ([username rangeOfCharacterFromSet:charSet].location == NSNotFound));
 }];


RAC(self.loginButton.enabled) = nameFieldValid;



// I'm not sure where 'executing' comes from, it's not in the sample code I copied
RACSignal *notProcessing = [executing map:^(NSNumber *x) {
  return @(!x.boolValue);
}];
RACSignal *fieldTextColor = [executing map:^(NSNumber *x) {
  return x.boolValue ? UIColor.lightGrayColor : UIColor.blackColor;
}];

RAC(self.firstNameField.textColor) = fieldTextColor;
RAC(self.lastNameField.textColor) = fieldTextColor;
RAC(self.emailField.textColor) = fieldTextColor;
RAC(self.reEmailField.textColor) = fieldTextColor;

RAC(self.firstNameField.enabled) = notProcessing;
RAC(self.lastNameField.enabled) = notProcessing;
RAC(self.emailField.enabled) = notProcessing;
RAC(self.reEmailField.enabled) = notProcessing;


RAC(self.textField.text) = RACAble(self.viewModel.title);
[[RACAble(self.scoreStepper.value) take:self.viewModel.maxPointUpdates] subscribeNext:^(id newPoints) {
    bself.viewModel.points = [newPoints doubleValue];
}];

[[[[self.uploadButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   skip:(kMaxUploads - 1)] take:1] subscribeNext:^(id x) {
    bself.nameField.enabled = NO;
    bself.scoreStepper.hidden = YES;
    bself.uploadButton.hidden = YES;
    }];


[[RACSignal
    combineLatest:@[ RACAble(self.password), RACAble(self.passwordConfirmation) ]
    reduce:^(NSString *currentPassword, NSString *currentConfirmPassword) {
        return [NSNumber numberWithBool:[currentConfirmPassword isEqualToString:currentPassword]];
    }]
    subscribeNext:^(NSNumber *passwordsMatch) {
        self.createEnabled = [passwordsMatch boolValue];
    }];


[self
    rac_bind:@keypath(self.helpLabel.text)
    to:[[RACAble(self.help)
        filter:^(NSString *newHelp) {
            return newHelp != nil;
        }]
        map:^(NSString *newHelp) {
            return [newHelp uppercaseString];
        }]];


[[RACSignal
    merge:@[ [client fetchUserRepos], [client fetchOrgRepos] ]]
    subscribeCompleted:^{
        NSLog(@"They're both done!");
    }];


[[[[client
    loginUser]
    flattenMap:^(id _) {
        return [client loadCachedMessages];
    }]
    flattenMap:^(id _) {
        return [client fetchMessages];
    }]
    subscribeCompleted:^{
        NSLog(@"Fetched all messages.");
    }];


[[[[[client
    fetchUserWithUsername:@"joshaber"]
    deliverOn:[RACScheduler scheduler]]
    map:^(User *user) {
        // this is on a background queue
        return [[NSImage alloc] initWithContentsOfURL:user.avatarURL];
    }]
    deliverOn:RACScheduler.mainThreadScheduler]
    subscribeNext:^(NSImage *image) {
        // now we're back on the main queue
        self.imageView.image = image;
    }];


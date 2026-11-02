class UserNamePage extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController fullNameController;
  const UserNamePage({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.fullNameController,
  });

  @override
  State<UserNamePage> createState() => _UserNamePageState();
}

class _UserNamePageState extends State<UserNamePage> {
  final userNameController = TextEditingController();

  bool isToastShowed = false;
  bool validateEdits = false;
  bool isFieldEmpty = true;
  bool isHeMovedToHome = false;

  @override
  void initState() {
    super.initState();
    userNameController.addListener(_onUserNameChanged);
  }

  void _onUserNameChanged() {
    final text = userNameController.text;
    setState(() {
      isFieldEmpty = text.isEmpty;
    });

    // Debounce or direct query trigger to block
    SearchAboutUserBloc.get(context).add(
      FindSpecificUser(text, searchForSingleLetter: true),
    );
  }

  @override
  void dispose() {
    userNameController.removeListener(_onUserNameChanged);
    userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: isThatMobile
              ? SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: buildColumn(context),
                )
              : buildForWeb(context),
        ),
      ),
    );
  }

  Widget buildColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        Text(
          StringsManager.createUserName.tr,
          style:
              getMediumStyle(color: Theme.of(context).focusColor, fontSize: 15),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            StringsManager.addUserName.tr,
            style: getNormalStyle(color: ColorManager.grey, fontSize: 13),
          ),
        ),
        Text(
          StringsManager.youCanChangeUserNameLater.tr,
          style: getNormalStyle(color: ColorManager.grey, fontSize: 13),
        ),
        const SizedBox(height: 30),
        userNameTextField(context),
        customTextButton(),
      ],
    );
  }

  SizedBox buildForWeb(BuildContext context) {
    return SizedBox(
      width: 352,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.2),
            ),
            child: buildColumn(context),
          ),
        ],
      ),
    );
  }

  Widget userNameTextField(BuildContext context) {
    return BlocConsumer<SearchAboutUserBloc, SearchAboutUserState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state is SearchAboutUserBlocLoaded) {
          setState(() {
            final usersWithSameUserName = state.users;
            validateEdits = usersWithSameUserName.isEmpty && !isFieldEmpty;
          });
        }
      },
      buildWhen: (previous, current) =>
          previous != current && current is SearchAboutUserBlocLoaded,
      builder: (context, state) {
        return customTextField(context);
      },
    );
  }

  Padding customTextField(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
      child: SizedBox(
        height: isThatMobile ? null : 37,
        width: double.infinity,
        child: TextField(
          controller: userNameController,
          cursorColor: ColorManager.teal,
          style:
              getNormalStyle(color: Theme.of(context).focusColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: StringsManager.username.tr,
            hintStyle: isThatMobile
                ? getNormalStyle(
                    color: Theme.of(context).tabBarTheme.indicatorColor!)
                : getNormalStyle(color: ColorManager.black54, fontSize: 12),
            fillColor: const Color.fromARGB(48, 232, 232, 232),
            filled: true,
            focusedBorder: outlineInputBorder(),
            suffixIcon: isFieldEmpty
                ? null
                : (validateEdits ? rightIcon() : wrongIcon()),
            enabledBorder: outlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
                horizontal: 10, vertical: isThatMobile ? 15 : 5),
            errorText: (isFieldEmpty || validateEdits)
                ? null
                : (isThatMobile ? StringsManager.thisUserNameExist.tr : null),
            errorStyle: getNormalStyle(color: ColorManager.red),
          ),
        ),
      ),
    );
  }

  Icon rightIcon() {
    return const Icon(Icons.check_rounded, color: ColorManager.green, size: 27);
  }

  Widget wrongIcon() {
    return const Icon(
      Icons.close_rounded,
      color: ColorManager.red,
      size: 27,
    );
  }

  OutlineInputBorder outlineInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(isThatMobile ? 5.0 : 1.0),
      borderSide: BorderSide(
          color: ColorManager.lightGrey, width: isThatMobile ? 1.0 : 0.8),
    );
  }

  Widget customTextButton() {
    return Builder(builder: (context) {
      FireStoreAddNewUserCubit userCubit =
          FireStoreAddNewUserCubit.get(context);
      return BlocConsumer<FirebaseAuthCubit, FirebaseAuthCubitState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) {
          if (state is CubitAuthConfirmed) {
            addNewUser(state, userCubit);
            moveToMain(state);
          } else if (state is CubitAuthFailed && !isToastShowed) {
            ToastShow.toastStateError(state.error);
          }
        },
        buildWhen: (previous, current) => previous != current,
        builder: (context, authState) {
          return CustomElevatedButton(
            isItDone: authState is! CubitAuthConfirming,
            nameOfButton: StringsManager.signUp.tr,
            blueColor: validateEdits,
            onPressed: () async {
              FirebaseAuthCubit authCubit = FirebaseAuthCubit.get(context);

              if (validateEdits) {
                setState(() => isToastShowed = false);

                await authCubit.signUp(RegisteredUser(
                  email: widget.emailController.text.trim(),
                  password: widget.passwordController.text.trim(),
                ));
              }
            },
          );
        },
      );
    });
  }

  Future<void> moveToMain(CubitAuthConfirmed authState) async {
    myPersonalId = authState.user.uid;

    final SharedPreferences sharePrefs = injector<SharedPreferences>();
    if (!isHeMovedToHome) {
      setState(() => isHeMovedToHome = true);

      if (myPersonalId.isNotEmpty) {
        await sharePrefs.setString("myPersonalId", myPersonalId);
        Get.offAll(GetMyPersonalInfo(myPersonalId: myPersonalId));
      } else {
        ToastShow.toast(StringsManager.somethingWrong.tr);
      }
    }
  }

  void addNewUser(
      CubitAuthConfirmed authState, FireStoreAddNewUserCubit userCubit) {
    String fullName = widget.fullNameController.text;
    List<dynamic> charactersOfName = [];
    String nameOfLower = fullName.toLowerCase();

    for (int i = 0; i < nameOfLower.length; i++) {
      charactersOfName = charactersOfName + [nameOfLower.substring(0, i + 1)];
    }
    String userName = userNameController.text;
    UserPersonalInfo newUserInfo = UserPersonalInfo(
      name: fullName,
      charactersOfName: charactersOfName,
      email: authState.user.email!,
      userName: userName,
      bio: "",
      profileImageUrl: "",
      userId: authState.user.uid,
      followerPeople: const [],
      followedPeople: const [],
      posts: const [],
      chatsOfGroups: const [],
      stories: const [],
      lastThreePostUrls: const [],
    );
    userCubit.addNewUser(newUserInfo);
  }
}

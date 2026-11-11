import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xrinet/core/utility/saved_account_storage.dart';
import 'package:xrinet/presentation/pages/register/login_page.dart';
import 'package:xrinet/presentation/pages/register/sign_up_page.dart';

class AccountSelectorPage extends StatefulWidget {
  const AccountSelectorPage({super.key});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  List<Map<String, dynamic>> accounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final savedAccounts = await SavedAccountStorage.getAccounts();

    if (!mounted) return;

    setState(() {
      accounts = savedAccounts;
      isLoading = false;
    });
  }

  void openLogin(Map<String, dynamic> account) {
    Get.to(() => LoginPage(initialEmail: account['email']?.toString() ?? ''));
  }

  Widget accountAvatar(String imageUrl, {double radius = 25}) {
    return CircleAvatar(
      radius: radius,
      child: imageUrl.isEmpty
          ? const Icon(Icons.person)
          : ClipOval(
              child: Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.person),
              ),
            ),
    );
  }

  Widget singleAccountCard(Map<String, dynamic> account) {
    final name = account['name']?.toString() ?? '';
    final userName = account['userName']?.toString() ?? '';
    final email = account['email']?.toString() ?? '';
    final imageUrl = account['profileImageUrl']?.toString() ?? '';
    final displayName = name.isEmpty ? userName : name;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            accountAvatar(imageUrl, radius: 42),
            const SizedBox(height: 14),
            Text(
              displayName.isEmpty ? 'XRINet User' : displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (userName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '@$userName',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => openLogin(account),
                child: Text(
                  displayName.isEmpty ? 'Continue' : 'Continue as $displayName',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget multipleAccountCard(Map<String, dynamic> account) {
    final name = account['name']?.toString() ?? '';
    final userName = account['userName']?.toString() ?? '';
    final email = account['email']?.toString() ?? '';
    final imageUrl = account['profileImageUrl']?.toString() ?? '';

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openLogin(account),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              accountAvatar(imageUrl),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? userName : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userName.isEmpty ? email : '@$userName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasManyAccounts = accounts.length > 6;
    final columns = accounts.length == 1 ? 1 : 2;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 24),
                      const Icon(Icons.account_circle_outlined, size: 55),
                      const SizedBox(height: 12),
                      const Text(
                        'Welcome back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose an account to continue',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (accounts.length == 1)
                        singleAccountCard(accounts.first)
                      else if (accounts.length > 1)
                        SizedBox(
                          height: hasManyAccounts ? 330 : null,
                          child: GridView.builder(
                            shrinkWrap: !hasManyAccounts,
                            physics: hasManyAccounts
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: accounts.length,
                            itemBuilder: (context, index) =>
                                multipleAccountCard(accounts[index]),
                          ),
                        )
                      else
                        const Center(child: Text('No saved accounts found.')),
                      const SizedBox(height: 20),
                      actionButton(
                        title: 'Log into another account',
                        icon: Icons.login,
                        onTap: () => Get.to(() => const LoginPage()),
                      ),
                      const SizedBox(height: 8),
                      actionButton(
                        title: 'Create a new account',
                        icon: Icons.person_add_alt_1,
                        onTap: () => Get.to(() => SignUpPage()),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

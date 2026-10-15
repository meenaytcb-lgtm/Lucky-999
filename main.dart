import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DubaiStarterApp());
}

class DubaiStarterApp extends StatelessWidget {
  const DubaiStarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dubai 777 Starter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB58A36), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF101114),
        useMaterial3: true,
        cardTheme: const CardThemeData(color: Color(0xFF1B1D22)),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.data == null ? const AuthScreen() : const MainShell();
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final referral = TextEditingController();
  bool register = false, busy = false;

  Future<void> submit() async {
    setState(() => busy = true);
    try {
      final auth = FirebaseAuth.instance;
      UserCredential credential;
      if (register) {
        credential = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(), password: password.text,
        );
        final uid = credential.user!.uid;
        final code = uid.substring(0, 8).toUpperCase();
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email.text.trim(),
          'referralCode': code,
          'referredBy': referral.text.trim().isEmpty ? null : referral.text.trim().toUpperCase(),
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        });
      } else {
        await auth.signInWithEmailAndPassword(email: email.text.trim(), password: password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? e.code)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete request: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose(); password.dispose(); referral.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Icon(Icons.diamond_outlined, size: 56, color: Color(0xFFD5AD59)),
                const SizedBox(height: 12),
                Text(register ? 'Create account' : 'Welcome back', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextField(controller: email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (min 6 characters)', border: OutlineInputBorder())),
                if (register) ...[
                  const SizedBox(height: 12),
                  TextField(controller: referral, decoration: const InputDecoration(
                    labelText: 'Referral code (optional)', border: OutlineInputBorder())),
                ],
                const SizedBox(height: 18),
                FilledButton(onPressed: busy ? null : submit,
                  child: Text(busy ? 'Please wait…' : register ? 'Register' : 'Login')),
                TextButton(onPressed: () => setState(() => register = !register),
                  child: Text(register ? 'Already registered? Login' : 'New user? Create account')),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int tab = 0;
  final pages = const [HomeTab(), WalletTab(), PredictionTab(), ReferralTab(), SupportTab()];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DUBAI 777 • STARTER'), actions: [
      IconButton(tooltip: 'Sign out', onPressed: () => FirebaseAuth.instance.signOut(), icon: const Icon(Icons.logout)),
    ]),
    body: pages[tab],
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (v) => setState(() => tab = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
        NavigationDestination(icon: Icon(Icons.casino_outlined), label: 'Predict'),
        NavigationDestination(icon: Icon(Icons.people_outline), label: 'Refer'),
        NavigationDestination(icon: Icon(Icons.support_agent), label: 'Support'),
      ],
    ),
  );
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Color(0xFF473719), Color(0xFF1B1D22)]),
      ),
      child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('WELCOME', style: TextStyle(color: Color(0xFFE4C16A), letterSpacing: 2)),
        SizedBox(height: 8),
        Text('Your game hub', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('Demo mode • No real-money wagering or payouts'),
      ]),
    ),
    const SizedBox(height: 16),
    const FeatureTile(icon: Icons.receipt_long, title: 'Passbook', subtitle: 'View request history'),
    const FeatureTile(icon: Icons.insights, title: 'Prediction Zone', subtitle: 'Practice predictions only'),
    const FeatureTile(icon: Icons.support_agent, title: 'Customer Support', subtitle: 'Send a support ticket'),
  ]);
}

class FeatureTile extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const FeatureTile({super.key, required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(icon, color: const Color(0xFFD5AD59)), title: Text(title), subtitle: Text(subtitle)));
}

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});
  Future<void> request(String type, BuildContext context) async {
    final amountController = TextEditingController();
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'deposit' ? 'Request add funds' : 'Request withdrawal'),
        content: TextField(controller: amountController, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (demo request only)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, int.tryParse(amountController.text)),
            child: const Text('Submit')),
        ],
      ),
    );
    amountController.dispose();
    if (amount == null) return;
    if (amount < 1 || amount > 100000) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount between 1 and 100000')));
      return;
    }
    try {
      await FirebaseFunctions.instance.httpsCallable('createWalletRequest').call({'type': type, 'amount': amount});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent for admin review. No money was moved.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(padding: EdgeInsets.all(18), child: Text(
        'Wallet is in demo mode. This starter does not hold or move real funds.', style: TextStyle(fontSize: 16)))),
      Row(children: [
        Expanded(child: FilledButton.icon(onPressed: () => request('deposit', context),
          icon: const Icon(Icons.add), label: const Text('Add Fund Request'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(onPressed: () => request('withdraw', context),
          icon: const Icon(Icons.south_west), label: const Text('Withdraw Request'))),
      ]),
      const SizedBox(height: 16),
      Text('Passbook / requests', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('walletRequests').where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true).limit(50).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Text('Could not load requests: ${snap.error}');
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Text('No requests yet.');
          return Column(children: snap.data!.docs.map((d) {
            final x = d.data();
            return Card(child: ListTile(
              leading: Icon(x['type'] == 'deposit' ? Icons.add_circle_outline : Icons.remove_circle_outline),
              title: Text('${x['type']} • ${x['amount']}'),
              subtitle: Text('Status: ${x['status'] ?? 'pending'}'),
              trailing: const Icon(Icons.chevron_right),
            ));
          }).toList());
        },
      ),
    ]);
  }
}

class PredictionTab extends StatelessWidget {
  const PredictionTab({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    const Text('Prediction Zone', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Practice-only sample. No stake, wallet deduction, prize, or payout is available.'),
    const SizedBox(height: 16),
    Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sample question: Which number is even?', style: TextStyle(fontSize: 18)),
      const SizedBox(height: 12),
      for (final n in [3, 6, 9]) Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(n == 6 ? 'Correct — practice mode only.' : 'Try again — practice mode only.'))),
          child: Text('$n')),
      ),
    ]))),
  ]);
}

class ReferralTab extends StatelessWidget {
  const ReferralTab({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final code = snap.data?.data()?['referralCode'] ?? 'Creating…';
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Card(
          child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_alt_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Your referral code'),
            const SizedBox(height: 8),
            SelectableText('$code', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Referral rewards are disabled until anti-abuse rules and terms are implemented.'),
          ]),
        )));
      },
    );
  }
}

class SupportTab extends StatefulWidget {
  const SupportTab({super.key});
  @override
  State<SupportTab> createState() => _SupportTabState();
}
class _SupportTabState extends State<SupportTab> {
  final subject = TextEditingController();
  final message = TextEditingController();
  bool busy = false;
  Future<void> send() async {
    if (subject.text.trim().isEmpty || message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter subject and message')));
      return;
    }
    setState(() => busy = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'uid': uid, 'subject': subject.text.trim(), 'message': message.text.trim(),
        'status': 'open', 'createdAt': FieldValue.serverTimestamp(),
      });
      subject.clear(); message.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support ticket submitted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not submit: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { subject.dispose(); message.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Customer Support', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 16),
    TextField(controller: subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: message, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'How can we help?', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    FilledButton(onPressed: busy ? null : send, child: Text(busy ? 'Sending…' : 'Submit ticket')),
  ]);
}

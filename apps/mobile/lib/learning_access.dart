import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _laBrown = Color(0xFF4A3022);
const _laGold = Color(0xFFC99A3D);
const _laCream = Color(0xFFF7F5F1);
const _laMuted = Color(0xFF746D66);

String _naira(dynamic value) {
  final amount = double.tryParse(value?.toString() ?? '') ?? 0;
  return '₦' + amount.toStringAsFixed(2);
}

String _requestStatus(String value) {
  switch (value) {
    case 'awaiting_payment': return 'Awaiting payment';
    case 'payment_submitted': return 'Payment submitted';
    case 'approved': return 'Approved';
    case 'rejected': return 'Needs attention';
    default: return value;
  }
}

class LearningAccessPage extends StatefulWidget {
  const LearningAccessPage({super.key});
  @override
  State<LearningAccessPage> createState() => _LearningAccessPageState();
}

class _LearningAccessPageState extends State<LearningAccessPage> {
  late Future<Map<String, dynamic>> _data;
  bool _busy = false;

  @override
  void initState() { super.initState(); _data = _load(); }

  Future<Map<String, dynamic>> _load() async {
    final db = Supabase.instance.client;
    final results = await Future.wait<dynamic>([
      db.from('learning_programmes').select('id,title,stage,level,description,duration_label,fee').eq('is_active', true).order('stage').order('level'),
      db.from('learning_access_requests').select('id,learner_name,level,programme_title,amount_due,status,payment_reference,payment_amount,payment_note,admin_note,created_at').order('created_at', ascending: false),
      db.from('learning_payment_settings').select('bank_name,account_name,account_number,payment_instructions').eq('id', 1).maybeSingle(),
      db.from('profiles').select('full_name').eq('id', Supabase.instance.client.auth.currentUser!.id).maybeSingle(),
    ]);
    return {
      'programmes': List<Map<String, dynamic>>.from(results[0]),
      'requests': List<Map<String, dynamic>>.from(results[1]),
      'settings': results[2] as Map<String, dynamic>?,
      'profile': results[3] as Map<String, dynamic>?,
    };
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _data = next);
    await next;
  }

  Future<void> _requestProgramme(Map<String, dynamic> programme, String learnerName) async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.rpc('create_learning_access_request', params: {
        'p_programme_id': programme['id'],
        'p_learner_name': learnerName.trim(),
        'p_level': programme['level'],
      });
      await _refresh();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Learning request created. Review the bank details below to make payment.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _showPayment(Map<String, dynamic> request, Map<String, dynamic>? settings) async {
    final amount = TextEditingController(text: request['amount_due'].toString());
    final reference = TextEditingController();
    final note = TextEditingController();
    final bank = settings ?? {};
    final bankConfigured = (bank['bank_name'] ?? '').toString().trim().isNotEmpty &&
        (bank['account_name'] ?? '').toString().trim().isNotEmpty &&
        (bank['account_number'] ?? '').toString().trim().length >= 8;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Submit payment details'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Transfer to the account below. Confirm the account name before sending money.'),
        if (!bankConfigured) ...[
          const SizedBox(height: 10),
          const Text('The tutorial centre has not added its bank details yet. You can return later to complete payment.', style: TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _laCream, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bank: ${bank['bank_name'] ?? 'Not configured'}'),
          const SizedBox(height: 4), Text('Account name: ${bank['account_name'] ?? 'Not configured'}'),
          const SizedBox(height: 4), SelectableText('Account number: ${bank['account_number'] ?? 'Not configured'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if ((bank['payment_instructions'] ?? '').toString().isNotEmpty) ...[const SizedBox(height: 6), Text(bank['payment_instructions'].toString())],
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: (bank['account_number'] ?? '').toString().isEmpty ? null : () => Clipboard.setData(ClipboardData(text: bank['account_number'].toString())), icon: const Icon(Icons.copy, size: 16), label: const Text('Copy account number'))),
        ])),
        const SizedBox(height: 12),
        Text('Programme fee: ${_naira(request['amount_due'])}', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount transferred (₦)')),
        const SizedBox(height: 10),
        TextField(controller: reference, decoration: const InputDecoration(labelText: 'Bank transfer reference')),
        const SizedBox(height: 10),
        TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Additional note (optional)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: bankConfigured ? () => Navigator.pop(ctx, true) : null, child: const Text('Submit payment'))],
    ));
    if (ok == true) {
      final value = double.tryParse(amount.text.trim());
      if (value == null || reference.text.trim().length < 3) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount and transfer reference.')));
      } else {
        setState(() => _busy = true);
        try {
          await Supabase.instance.client.rpc('submit_learning_payment', params: {
            'p_request_id': request['id'], 'p_amount': value,
            'p_reference': reference.text.trim(), 'p_note': note.text.trim(),
          });
          await _refresh();
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment details submitted for verification.')));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        } finally { if (mounted) setState(() => _busy = false); }
      }
    }
    amount.dispose(); reference.dispose(); note.dispose();
  }

  Future<void> _chooseProgramme(List<Map<String, dynamic>> programmes, String name) async {
    if (programmes.isEmpty) return;
    Map<String, dynamic> selected = programmes.first;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
      title: const Text('Choose a learning programme'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        DropdownButtonFormField<String>(
          value: selected['id'].toString(),
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Programme'),
          items: programmes.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['title']} • ${_naira(p['fee'])}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (value) => refresh(() => selected = programmes.firstWhere((p) => p['id'].toString() == value)),
        ),
        const SizedBox(height: 12),
        Text(selected['description']?.toString() ?? 'Learning support for ${selected['level']}.'),
        const SizedBox(height: 8),
        Text('${selected['duration_label']} • ${_naira(selected['fee'])}', style: const TextStyle(fontWeight: FontWeight.w800, color: _laBrown)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue'))],
    )));
    if (ok == true) await _requestProgramme(selected, name);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _laCream,
    appBar: AppBar(title: const Text('Learning programmes'), backgroundColor: _laCream),
    body: RefreshIndicator(onRefresh: _refresh, child: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _laBrown));
        if (snapshot.hasError) return ListView(padding: const EdgeInsets.all(20), children: [Text('Learning options could not be loaded: ${snapshot.error}')]);
        final data = snapshot.data!;
        final programmes = List<Map<String, dynamic>>.from(data['programmes'] as List);
        final requests = List<Map<String, dynamic>>.from(data['requests'] as List);
        final settings = data['settings'] as Map<String, dynamic>?;
        final profile = data['profile'] as Map<String, dynamic>?;
        final name = (profile?['full_name'] ?? '').toString();
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Start learning', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _laBrown)),
          const SizedBox(height: 6),
          const Text('Choose a programme that matches your class level. Your account is free; payment is only required for the learning programme you choose.', style: TextStyle(color: _laMuted, height: 1.45)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _busy || programmes.isEmpty ? null : () => _chooseProgramme(programmes, name), icon: const Icon(Icons.add), label: const Text('Request a learning programme'), style: FilledButton.styleFrom(backgroundColor: _laBrown, padding: const EdgeInsets.symmetric(vertical: 14))),
          if (programmes.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('No programmes are available yet. Please check again later.')),
          const SizedBox(height: 22),
          const Text('MY REQUESTS', style: TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800, color: _laMuted)),
          const SizedBox(height: 10),
          if (requests.isEmpty) const Text('You have not requested classroom access yet.', style: TextStyle(color: _laMuted)),
          ...requests.map((r) {
            final status = r['status'].toString();
            return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['programme_title']?.toString() ?? 'Learning programme', style: const TextStyle(fontWeight: FontWeight.w800, color: _laBrown, fontSize: 16)),
              const SizedBox(height: 5),
              Text('${r['learner_name']} • ${r['level']} • ${_naira(r['amount_due'])}', style: const TextStyle(color: _laMuted)),
              const SizedBox(height: 8),
              Text(_requestStatus(status), style: TextStyle(fontWeight: FontWeight.w700, color: status == 'approved' ? Colors.green.shade700 : _laBrown)),
              if ((r['admin_note'] ?? '').toString().isNotEmpty) Text('Admin note: ${r['admin_note']}'),
              if (status == 'awaiting_payment' || status == 'rejected') Align(alignment: Alignment.centerRight, child: FilledButton(onPressed: _busy ? null : () => _showPayment(r, settings), style: FilledButton.styleFrom(backgroundColor: _laBrown), child: const Text('Make / resubmit payment'))),
              if (status == 'payment_submitted') const Text('Your payment is being checked. We will notify you when the review is complete.', style: TextStyle(color: _laMuted)),
              if (status == 'approved') const Text('Your programme has been approved. Classroom access is now authorised for this programme.', style: TextStyle(color: Colors.green)),
            ])));
          }),
        ]);
      },
    )),
  );
}

class OwnerLearningAccessPage extends StatefulWidget {
  final bool owner;
  final bool canManageFinance;
  const OwnerLearningAccessPage({super.key, this.owner = false, this.canManageFinance = false});
  @override
  State<OwnerLearningAccessPage> createState() => _OwnerLearningAccessPageState();
}

class _OwnerLearningAccessPageState extends State<OwnerLearningAccessPage> {
  late Future<Map<String, dynamic>> _data;
  bool _busy = false;
  final _bank = TextEditingController();
  final _accountName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _instructions = TextEditingController();

  @override
  void initState() { super.initState(); _data = _load(); }
  @override
  void dispose() { _bank.dispose(); _accountName.dispose(); _accountNumber.dispose(); _instructions.dispose(); super.dispose(); }

  Future<Map<String, dynamic>> _load() async {
    final db = Supabase.instance.client;
    final results = await Future.wait<dynamic>([
      db.from('learning_access_requests').select('id,user_id,learner_name,level,programme_title,amount_due,status,payment_amount,payment_reference,payment_note,admin_note,created_at').order('created_at', ascending: false),
      db.from('learning_payment_settings').select('bank_name,account_name,account_number,payment_instructions').eq('id', 1).maybeSingle(),
      widget.owner ? db.from('learning_programmes').select('id,title,stage,level,duration_label,fee,is_active,class_id').order('created_at', ascending: false) : Future.value([]),
      widget.owner ? db.from('classes').select('id,name,level').eq('status', 'active').order('name') : Future.value([]),
    ]);
    final settings = results[1] as Map<String, dynamic>?;
    _bank.text = settings?['bank_name']?.toString() ?? '';
    _accountName.text = settings?['account_name']?.toString() ?? '';
    _accountNumber.text = settings?['account_number']?.toString() ?? '';
    _instructions.text = settings?['payment_instructions']?.toString() ?? '';
    return {'requests': List<Map<String, dynamic>>.from(results[0]), 'programmes': List<Map<String, dynamic>>.from(results[2]), 'classes': List<Map<String, dynamic>>.from(results[3])};
  }

  Future<void> _refresh() async { final next = _load(); setState(() => _data = next); await next; }

  Future<void> _saveBank() async {
    if (_bank.text.trim().isEmpty || _accountName.text.trim().isEmpty || _accountNumber.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the bank, account name and a valid account number.'))); return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.from('learning_payment_settings').upsert({
        'id': 1, 'bank_name': _bank.text.trim(), 'account_name': _accountName.text.trim(),
        'account_number': _accountNumber.text.trim(), 'payment_instructions': _instructions.text.trim(),
        'updated_by': Supabase.instance.client.auth.currentUser!.id, 'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank payment details saved.')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save bank details: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveProgramme(List<Map<String, dynamic>> classes, [Map<String, dynamic>? existing]) async {
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final level = TextEditingController(text: existing?['level']?.toString() ?? '');
    final description = TextEditingController(text: existing?['description']?.toString() ?? '');
    final fee = TextEditingController(text: existing?['fee']?.toString() ?? '');
    final duration = TextEditingController(text: existing?['duration_label']?.toString() ?? 'Monthly');
    String stage = existing?['stage']?.toString() ?? 'Primary';
    final existingClassId = existing?['class_id']?.toString();
    String? selectedClassId = classes.any((c) => c['id'].toString() == existingClassId)
        ? existingClassId : (classes.isEmpty ? null : classes.first['id'].toString());
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
      title: Text(existing == null ? 'Add learning programme' : 'Edit learning programme'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Programme name')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: stage, decoration: const InputDecoration(labelText: 'Stage'), items: const [DropdownMenuItem(value: 'Primary', child: Text('Primary')),DropdownMenuItem(value: 'JSS', child: Text('Junior Secondary')),DropdownMenuItem(value: 'SS', child: Text('Senior Secondary'))], onChanged: (v) => refresh(() => stage = v ?? 'Primary')),
        const SizedBox(height: 8), TextField(controller: level, decoration: const InputDecoration(labelText: 'Class level (e.g. Primary 4, JSS2)')),
        const SizedBox(height: 8), TextField(controller: fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee in Naira')),
        const SizedBox(height: 8), TextField(controller: duration, decoration: const InputDecoration(labelText: 'Duration / billing period')),
        const SizedBox(height: 8), TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'What is included?')),
        const SizedBox(height: 8),
        if (classes.isEmpty) const Text('Create an active class in Academic Management before adding a programme.')
        else DropdownButtonFormField<String>(value: selectedClassId, isExpanded: true, decoration: const InputDecoration(labelText: 'Connect to classroom'), items: classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text('${c['name']}'))).toList(), onChanged: (v) => refresh(() => selectedClassId = v)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing == null ? 'Save programme' : 'Update programme'))],
    )));
    if (ok == true) {
      final amount = double.tryParse(fee.text.trim());
      if (title.text.trim().isEmpty || level.text.trim().isEmpty || amount == null || amount <= 0 || selectedClassId == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name, class level and valid fee.')));
      } else {
        setState(() => _busy = true);
        try {
          final values = {
            'title': title.text.trim(), 'stage': stage, 'level': level.text.trim(),
            'fee': amount, 'duration_label': duration.text.trim().isEmpty ? 'Monthly' : duration.text.trim(),
            'description': description.text.trim(), 'class_id': selectedClassId,
          };
          if (existing == null) {
            await Supabase.instance.client.from('learning_programmes').insert({...values, 'is_active': true});
          } else {
            await Supabase.instance.client.from('learning_programmes').update(values).eq('id', existing['id']);
          }
          await _refresh();
        } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create programme: $e'))); }
        finally { if (mounted) setState(() => _busy = false); }
      }
    }
    title.dispose(); level.dispose(); description.dispose(); fee.dispose(); duration.dispose();
  }

  Future<void> _review(Map<String, dynamic> request, String decision) async {
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(decision == 'approved' ? 'Approve learning access?' : 'Reject payment submission?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Learner: ${request['learner_name']}\nProgramme: ${request['programme_title']}\nAmount reported: ${_naira(request['payment_amount'])}\nReference: ${request['payment_reference']}'),
        const SizedBox(height: 10), TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Note to learner (optional)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(decision == 'approved' ? 'Approve' : 'Reject'))],
    ));
    if (ok == true) {
      setState(() => _busy = true);
      try {
        await Supabase.instance.client.rpc('review_learning_access_request', params: {
          'p_request_id': request['id'], 'p_decision': decision, 'p_admin_note': note.text.trim(),
        });
        await _refresh();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decision == 'approved' ? 'Learning access approved.' : 'Payment submission rejected.')));
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
      finally { if (mounted) setState(() => _busy = false); }
    }
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _laCream,
    appBar: AppBar(title: const Text('Learning access & payments'), backgroundColor: _laCream),
    body: FutureBuilder<Map<String, dynamic>>(future: _data, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: _laBrown));
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Could not load payment administration: ${snapshot.error}')));
      final requests = List<Map<String, dynamic>>.from(snapshot.data!['requests']);
      final programmes = List<Map<String, dynamic>>.from(snapshot.data!['programmes']);
      final classes = List<Map<String, dynamic>>.from(snapshot.data!['classes']);
      final pending = requests.where((r) => r['status'] == 'payment_submitted').length;
      return RefreshIndicator(onRefresh: _refresh, child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Payment verification', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _laBrown)),
        const SizedBox(height: 5), Text('$pending payment submission(s) waiting for review', style: const TextStyle(color: _laMuted)),
        const SizedBox(height: 16),
        if (widget.canManageFinance) Card(child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BANK ACCOUNT DETAILS', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: _laMuted)),
          const SizedBox(height: 10),
          TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Bank name')),
          const SizedBox(height: 9), TextField(controller: _accountName, decoration: const InputDecoration(labelText: 'Account name')),
          const SizedBox(height: 9), TextField(controller: _accountNumber, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Account number')),
          const SizedBox(height: 9), TextField(controller: _instructions, maxLines: 2, decoration: const InputDecoration(labelText: 'Payment instructions (optional)')),
          const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _saveBank, style: FilledButton.styleFrom(backgroundColor: _laBrown), child: const Text('Save bank details'))),
        ]))),
        if (widget.owner) ...[
          const SizedBox(height: 12),
          Card(child: ListTile(leading: const Icon(Icons.add_circle_outline, color: _laBrown), title: const Text('Create a learning programme'), subtitle: const Text('Set the class level, price and duration.'), onTap: _busy ? null : () => _saveProgramme(classes))),
          const SizedBox(height: 8),
          ...programmes.map((p) => Card(child: SwitchListTile(
            secondary: IconButton(
              tooltip: 'Edit programme',
              onPressed: _busy ? null : () => _saveProgramme(classes, p),
              icon: const Icon(Icons.edit_outlined, color: _laBrown),
            ),
            value: p['is_active'] == true,
            onChanged: _busy ? null : (v) async {
              await Supabase.instance.client.from('learning_programmes').update({'is_active': v}).eq('id', p['id']);
              await _refresh();
            },
            title: Text(p['title'].toString()),
            subtitle: Text('${p['level']} • ${_naira(p['fee'])} • ${p['duration_label']}'),
          ))),
        ],
        const SizedBox(height: 20),
        const Text('LEARNING ACCESS REQUESTS', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: _laMuted)),
        const SizedBox(height: 8),
        if (requests.isEmpty) const Text('No learning requests have been submitted yet.', style: TextStyle(color: _laMuted)),
        ...requests.map((r) {
          final status = r['status'].toString();
          return Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['learner_name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: _laBrown, fontSize: 16)),
            Text('Account: ${r['user_id']} • ${r['programme_title']}'),
            const SizedBox(height: 5), Text('Fee: ${_naira(r['amount_due'])} • Reported: ${_naira(r['payment_amount'])}'),
            Text('Status: ${_requestStatus(status)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if ((r['payment_reference'] ?? '').toString().isNotEmpty) SelectableText('Transfer reference: ${r['payment_reference']}'),
            if ((r['payment_note'] ?? '').toString().isNotEmpty) Text('Learner note: ${r['payment_note']}'),
            if ((r['admin_note'] ?? '').toString().isNotEmpty) Text('Previous admin note: ${r['admin_note']}'),
            if (status == 'payment_submitted') Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: _busy ? null : () => _review(r, 'rejected'), child: const Text('Reject')),
              const SizedBox(width: 8), FilledButton(onPressed: _busy ? null : () => _review(r, 'approved'), style: FilledButton.styleFrom(backgroundColor: _laBrown), child: const Text('Verify & approve')),
            ]),
          ])));
        }),
      ]));
    }),
  );
}

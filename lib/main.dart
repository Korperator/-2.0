import 'package:flutter/material.dart';

void main() => runApp(const ChangeHelperApp());

class ChangeHelperApp extends StatelessWidget {
  const ChangeHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ресто лв/€',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ресто калкулатор')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Избери валутата, с която клиентът плаща:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentPage(paidCurrency: Currency.bgn),
                      ),
                    );
                  },
                  child: const Text('Заплати в лева'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentPage(paidCurrency: Currency.eur),
                      ),
                    );
                  },
                  child: const Text('Заплати в евро'),
                ),
              ),
              const Spacer(),
              const Text(
                'Курс: 1 € = 1.95583 лв',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

enum Currency { bgn, eur }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.paidCurrency});

  final Currency paidCurrency;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _paidCtrl = TextEditingController();
  final _dueCtrl = TextEditingController();

  String? _error;
  ChangeOutput? _output;

  @override
  void dispose() {
    _paidCtrl.dispose();
    _dueCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _error = null;
      _output = null;
    });

    final paidInput = MoneyInput.tryParse(_paidCtrl.text.trim());
    final dueInput = MoneyInput.tryParse(_dueCtrl.text.trim());

    if (paidInput == null || dueInput == null) {
      setState(() => _error = 'Моля въведи валидни суми (пример: 12.34).');
      return;
    }

    if (widget.paidCurrency == Currency.bgn) {
      final paidSt = Money.pairsToMinorUnits(paidInput); // stotinki
      final dueSt = Money.pairsToMinorUnits(dueInput); // stotinki

      if (paidSt < dueSt) {
        setState(() => _error = 'Заплатената сума е по-малка от дължимата.');
        return;
      }

      final changeSt = paidSt - dueSt;
      final changeEurCents = Money.bgnStotinkiToEurCents(changeSt);

      setState(() {
        _output = ChangeOutput(
          changeBgnStotinki: changeSt,
          changeEurCents: changeEurCents,
        );
      });
    } else {
      // EUR payment
      final paidCents = Money.pairsToMinorUnits(paidInput); // cents
      final dueCents = Money.pairsToMinorUnits(dueInput); // cents

      if (paidCents < dueCents) {
        setState(() => _error = 'Заплатената сума е по-малка от дължимата.');
        return;
      }

      final changeCents = paidCents - dueCents;
      final changeSt = Money.eurCentsToBgnStotinki(changeCents);

      setState(() {
        _output = ChangeOutput(
          changeBgnStotinki: changeSt,
          changeEurCents: changeCents,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBGN = widget.paidCurrency == Currency.bgn;

    final paidLabel = isBGN ? 'Заплатена сума в лева' : 'Заплатена сума в евро';
    final dueLabel = isBGN ? 'Дължима сума в лева' : 'Дължима сума в евро';

    return Scaffold(
      appBar: AppBar(
        title: Text(isBGN ? 'Плащане в лева' : 'Плащане в евро'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(paidLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _paidCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: isBGN ? 'например 20.00' : 'например 10.00',
                        suffixText: isBGN ? 'лв' : '€',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(dueLabel, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dueCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: isBGN ? 'например 13.50' : 'например 6.90',
                        suffixText: isBGN ? 'лв' : '€',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate),
                        label: const Text('Изчисли'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (_output != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ресто', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      _ResultRow(
                        label: 'В лева',
                        value: Money.formatBgnFromStotinki(_output!.changeBgnStotinki),
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _ResultRow(
                        label: 'В евро',
                        value: Money.formatEurFromCents(_output!.changeEurCents),
                        bold: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Показва рестото и в двете валути (курс 1€ = 1.95583 лв).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад към началото'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

/// Parsed monetary input: major + minor (2 decimals)
class MoneyInput {
  MoneyInput(this.major, this.minor);
  final int major;
  final int minor; // 0..99

  static MoneyInput? tryParse(String s) {
    if (s.isEmpty) return null;
    final normalized = s.replaceAll(',', '.');

    final reg = RegExp(r'^\s*(\d+)(?:\.(\d{1,2}))?\s*$');
    final m = reg.firstMatch(normalized);
    if (m == null) return null;

    final major = int.tryParse(m.group(1) ?? '');
    if (major == null) return null;

    final dec = m.group(2);
    int minor = 0;
    if (dec != null && dec.isNotEmpty) {
      minor = dec.length == 1 ? int.parse(dec) * 10 : int.parse(dec);
    }
    if (minor < 0 || minor > 99) return null;

    return MoneyInput(major, minor);
  }
}

class ChangeOutput {
  ChangeOutput({required this.changeBgnStotinki, required this.changeEurCents});
  final int changeBgnStotinki; // stotinki
  final int changeEurCents; // euro cents
}

/// Money helpers using fixed exchange rate 1 EUR = 1.95583 BGN.
/// Conversions are rounded to 2 decimals (cents/stotinki).
class Money {
  // exact rate
  static const double eurToBgnRate = 1.95583;

  static int pairsToMinorUnits(MoneyInput a) => a.major * 100 + a.minor;

  static String formatBgnFromStotinki(int st) {
    final major = st ~/ 100;
    final minor = st % 100;
    return '$major.${minor.toString().padLeft(2, '0')} лв';
  }

  static String formatEurFromCents(int cents) {
    final major = cents ~/ 100;
    final minor = cents % 100;
    return '€$major.${minor.toString().padLeft(2, '0')}';
  }

  static int eurCentsToBgnStotinki(int eurCents) {
    final eur = eurCents / 100.0;
    final bgn = eur * eurToBgnRate;
    return (bgn * 100.0).round(); // stotinki
  }

  static int bgnStotinkiToEurCents(int stotinki) {
    final bgn = stotinki / 100.0;
    final eur = bgn / eurToBgnRate;
    return (eur * 100.0).round(); // cents
  }
}

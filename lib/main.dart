import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Mortgage()..loadMortgage(),
      child: const MortgageApp(),
    ),
  );
}

class MortgageApp extends StatelessWidget {
  const MortgageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mortgage Calculator',
      home: MortgageScreen(),
    );
  }
}

class Mortgage extends ChangeNotifier {
  double amount;
  int years;
  double rate;

  Mortgage({
    this.amount = 100000.0,
    this.years = 30,
    this.rate = 0.035,
  });

  double monthlyPayment() {
    double monthlyRate = rate / 12;
    int months = years * 12;

    double temp = pow(1 / (1 + monthlyRate), months).toDouble();
    return amount * monthlyRate / (1 - temp);
  }

  double totalPayment() {
    return monthlyPayment() * years * 12;
  }

  Future<void> updateMortgage({
    required double newAmount,
    required int newYears,
    required double newRate,
  }) async {
    amount = newAmount;
    years = newYears;
    rate = newRate;

    notifyListeners();
    await saveMortgage();
  }

  Future<void> saveMortgage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('amount', amount);
    await prefs.setInt('years', years);
    await prefs.setDouble('rate', rate);
  }

  Future<void> loadMortgage() async {
    final prefs = await SharedPreferences.getInstance();

    amount = prefs.getDouble('amount') ?? 100000.0;
    years = prefs.getInt('years') ?? 30;
    rate = prefs.getDouble('rate') ?? 0.035;

    notifyListeners();
  }
}

class MortgageScreen extends StatefulWidget {
  const MortgageScreen({super.key});

  @override
  State<MortgageScreen> createState() => MortgageScreenState();
}

class MortgageScreenState extends State<MortgageScreen> {
  bool termsChecked = false;

  String money(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }

  void termsOfConditions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: const Text('Do you accept the terms and conditions?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void modify() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ModifyMortgageScreen(),
    ),
  );
}

  Widget row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mortgage = Provider.of<Mortgage>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mortgage Calculator'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Amount: ', money(mortgage.amount)),
            row('Years: ', mortgage.years.toString()),
            row('Interest Rate: ', '${(mortgage.rate * 100).toStringAsFixed(2)}%'),

            const Divider(thickness: 3, color: Colors.red),

            row('Monthly Payment: ', money(mortgage.monthlyPayment())),
            row('Total Payment: ', money(mortgage.totalPayment())),

            CheckboxListTile(
              title: const Text('Terms and Conditions'),
              value: termsChecked,
              onChanged: (value) {
                setState(() {
                  termsChecked = value!;
                });
                termsOfConditions();
              },
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: modify,
                child: const Text('MODIFY DATA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModifyMortgageScreen extends StatefulWidget {
  const ModifyMortgageScreen({super.key});

  @override
  State<ModifyMortgageScreen> createState() =>
      _ModifyMortgageScreenState();
}

class _ModifyMortgageScreenState extends State<ModifyMortgageScreen> {
  late TextEditingController amountController;
  int selectedYears = 30;
  double selectedRate = 0.035;

  @override
  void initState() {
    super.initState();

    final mortgage =
        Provider.of<Mortgage>(context, listen: false);

    amountController = TextEditingController(
      text: mortgage.amount.toStringAsFixed(2),
    );

    selectedYears = mortgage.years;
    selectedRate = mortgage.rate;
  }

  List<double> rateList() {
    List<double> rates = [];
    for (double rate = 2.0; rate <= 15.0; rate += 0.25) {
      rates.add(rate);
    }
    return rates;
  }

  void _done() async {
    double amount = double.tryParse(amountController.text) ?? 100000.0;

    final mortgage = Provider.of<Mortgage>(
      context,
      listen: false,
    );

    await mortgage.updateMortgage(
      newAmount: amount,
      newYears: selectedYears,
      newRate: selectedRate,
    );

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget yearRadio(int year) {
    return Row(
      children: [
        Radio<int>(
          value: year,
          groupValue: selectedYears,
          onChanged: (value) {
            setState(() {
              selectedYears = value!;
            });
          },
        ),
        Text(year.toString()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<double> rates = rateList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mortgage Calculator'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 90, child: Text('Years', style: TextStyle(fontSize: 16))),
                yearRadio(10),
                yearRadio(15),
                yearRadio(30),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const SizedBox(width: 90, child: Text('Amount', style: TextStyle(fontSize: 16))),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text('Interest Rate', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: rates.length,
                itemBuilder: (context, index) {
                  double ratePercent = rates[index];
                  double rateDecimal = ratePercent / 100;

                  return RadioListTile<double>(
                    title: Text('${ratePercent.toStringAsFixed(2)}%'),
                    value: rateDecimal,
                    groupValue: selectedRate,
                    onChanged: (value) {
                      setState(() {
                        selectedRate = value!;
                      });
                    },
                  );
                },
              ),
            ),

            Center(
              child: ElevatedButton(
                onPressed: _done,
                child: const Text('DONE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
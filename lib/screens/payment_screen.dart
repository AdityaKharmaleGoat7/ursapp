import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vendor.dart';
import 'dart:async';
import '../utils/logger.dart';
class PaymentScreen extends StatefulWidget {
  final String qrData;

  PaymentScreen({required this.qrData});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  Vendor? _vendor;
  bool _isLoading = true;
  bool _showSuccess = false;
  double _rewardPoints = 0.0;
  String? _senderUpiId = "user@upi"; // Replace with actual user's UPI ID
  String? _receiverUpiId; // Will store the receiver's UPI ID from the QR data
  int? _transactionId;

  @override
  void initState() {
    super.initState();
    _checkVendor();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _checkVendor() async {
    try {
      final upiUri = Uri.parse(widget.qrData);
      final upiId = upiUri.queryParameters['pa'];
      
      if (upiId != null) {
        final vendor = await _dbHelper.getVendorByUpiId(upiId);
        
        setState(() {
          _receiverUpiId = upiId;
          _vendor = vendor;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _receiverUpiId = null;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing QR code: $e')),
      );
    }
  }

  


  void _calculateRewardPoints(double amount) {
    if (_vendor != null) {
      double rewardPoints = 0.0;

      switch (_vendor!.type) {
        case 'small':
          if (amount >= 100) {
            rewardPoints = amount * 0.10;
          }
          break;
        case 'medium':
          if (amount >= 200) {
            rewardPoints = amount * 0.05;
          }
          break;
        case 'big':
          // No reward points for big vendors
          rewardPoints = 0.0;
          break;
        default:
          rewardPoints = 0.0;
          break;
      }

      setState(() {
        _rewardPoints = rewardPoints;
      });
    } else {
      // If vendor is not registered, no rewards apply
      setState(() {
        _rewardPoints = 0.0;
      });
    }
  }

  Future<void> _showConfirmationDialog() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to proceed with this payment?'),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount:'),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('To:'),
                  Text(
                    _vendor?.name ?? _receiverUpiId ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_rewardPoints > 0) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reward Points:'),
                    Text(
                      _rewardPoints.toStringAsFixed(2),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processPayment();
              },
              child: Text('Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate() || _receiverUpiId == null || _senderUpiId == null) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final transaction = {
        'sender_upi_id': _senderUpiId,
        'receiver_upi_id': _vendor?.upiId ?? _receiverUpiId,
        'amount': double.parse(_amountController.text),
        'date': DateTime.now().toIso8601String(),
        'reward_points': _vendor != null ? _rewardPoints.round() : 0,
      };

      final result = await _dbHelper.insertTransaction(transaction);

      setState(() {
        _isLoading = false;
        _showSuccess = true;
        _transactionId = result;
      });

      _animationController.forward();

      // Wait for 2 seconds before navigating back
      Timer(Duration(seconds: 2), () {
        Navigator.pop(context);
      });

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSuccessOverlay() {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Transaction ID: $_transactionId',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              if (_rewardPoints > 0) ...[
                SizedBox(height: 10),
                Text(
                  'Earned ${_rewardPoints.toStringAsFixed(2)} points!',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Payment'),
            elevation: 0,
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_vendor != null) ...[
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      _vendor!.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _vendor!.name,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    _vendor!.type.toUpperCase(),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (_rewardPoints > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        'Potential Reward: ${_rewardPoints.toStringAsFixed(2)} points',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                        ] else
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vendor not registered in our system'),
                                  SizedBox(height: 8),
                                  Text('UPI ID: ${_receiverUpiId ?? 'N/A'}'),
                                ],
                              ),
                            ),
                          ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  labelText: 'Enter Amount',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an amount';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (double.tryParse(value) != null) {
                                    _calculateRewardPoints(double.parse(value));
                                  }
                                },
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _pinController,
                                decoration: InputDecoration(
                                  labelText: 'Enter PIN',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your PIN';
                                  }
                                  if (value.length != 4) {
                                    return 'PIN should be 4 digits';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _receiverUpiId != null ? _showConfirmationDialog : null,
                                  child: Text(
                                    'Proceed to Payment',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (_showSuccess)
          _buildSuccessOverlay(),
      ],
    );
  }
}

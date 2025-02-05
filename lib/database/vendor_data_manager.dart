import 'database_helper.dart';
import '../models/vendor.dart';
import '../models/phone.dart';
import '../models/transaction.dart';
import '../utils/logger.dart';

class VendorDataManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> initializeVendors() async {
    // Check if vendors already exist
    final existingVendors = await _dbHelper.getAllVendors();
    
      await addSampleVendors();
 
    await _dbHelper.verifyVendorData(); 
  }

  Future<void> addSampleVendors() async {
    final vendors = [
      Vendor(
        vendorId: 'V001',
        upiId: 'chaitanyakumar160@okhdfcbank',
        name: 'John Store',
        type: 'medium',
        phoneNumber: '1234567890',
        location: 'New York',
      ),
      Vendor(
        vendorId: 'V002',
        upiId: 'asitmdesai@oksbi',
        name: 'Super Market',
        type: 'small',
        phoneNumber: '0987654321',
        location: 'Los Angeles',
      ),
      Vendor(
        vendorId: 'V003',
        upiId: 'vendor3@oksbi',
        name: 'Local Shop',
        type: 'medium',
        phoneNumber: '1122334455',
        location: 'Chicago',
      ),
      Vendor(
        vendorId: 'V004',
        upiId: 'adityakharmale7@oksbi',
        name: 'SDK Shop',
        type: 'small',
        phoneNumber: '2233445566',
        location: 'San Francisco',
      ),
      Vendor(
        vendorId: 'V005',
        upiId: 'vendor5@okhdfcbank',
        name: 'Fresh Mart',
        type: 'big',
        phoneNumber: '3344556677',
        location: 'Houston',
      ),
      Vendor(
        vendorId: 'V006',
        upiId: 'vendor6@okicici',
        name: 'City Bazaar',
        type: 'big',
        phoneNumber: '4455667788',
        location: 'Seattle',
      ),
      Vendor(
        vendorId: 'V007',
        upiId: 'vendor7@okaxis',
        name: 'Daily Needs',
        type: 'small',
        phoneNumber: '5566778899',
        location: 'Boston',
      ),
      Vendor(
        vendorId: 'V008',
        upiId: 'vendor8@oksbi',
        name: 'Mega Store',
        type: 'medium',
        phoneNumber: '6677889900',
        location: 'Miami',
      ),
      Vendor(
        vendorId: 'V009',
        upiId: 'vendor9@okhdfcbank',
        name: 'Grocery Hub',
        type: 'big',
        phoneNumber: '7788990011',
        location: 'Dallas',
      ),
      Vendor(
        vendorId: 'V010',
        upiId: 'vendor10@okicici',
        name: 'Food Basket',
        type: 'small',
        phoneNumber: '8899001122',
        location: 'Denver',
      ),
    ];

    for (var vendor in vendors) {
      await Logger.log('Adding vendor: ${vendor.toString()}');
      await _dbHelper.insertVendor(vendor);
    }
    await Logger.log('Sample vendors added successfully');
  }


  Future<void> addSamplePhones() async {
    final phones = [
      Phone(
        name: 'Adi',
        phoneNumber: '1234567890',  
      ),
      Phone(
        name: 'Johnny',
        phoneNumber: '0987654321', 
      ),
      Phone(
        name: 'Mac',
        phoneNumber: '1122334455',  
      ),
      Phone(
        name: 'steve',
        phoneNumber: '1122364455',  
      ),
    ];

    for (var phone in phones) {
      await _dbHelper.insertPhone(phone);
    }
  }
  Future<void> addSampleTransactions() async {
    final transactions = [
      // Transaction(
      //   senderUpiId: 'vendor1@oksbi',
      //   receiverUpiId: 'adityakharmale7@oksbi',
      //   amount: 100.0,
      //   date: '2023-10-01',
      //   rewardPoints: -10,
      // ),
      // Transaction(
      //   senderUpiId: 'asitmdesai@oksbi',
      //   receiverUpiId: 'vendor3@oksbi',
      //   amount: 200.0,
      //   date: '2023-10-02',
      //   rewardPoints: -5,
      // ),
      // Transaction(
      //   senderUpiId: 'adityakharmale7@oksbi',
      //   receiverUpiId: 'vendor1@oksbi',
      //   amount: 150.0,
      //   date: '2023-10-03',
      //   rewardPoints: 15,
      // ),
      // Transaction(
      //   senderUpiId: 'vendor3@oksbi',
      //   receiverUpiId: 'asitmdesai@oksbi',
      //   amount: 50.0,
      //   date: '2023-10-04',
      //   rewardPoints: 5,
      // ),
    ];

    for (var transaction in transactions) {
      await _dbHelper.insertTransaction(transaction.toMap());
    }
  }
}

class Vendor {
  final String vendorId;
  final String upiId;
  final String name;
  final String type;
  final String phoneNumber;
  final String location;  // Add the location field

  Vendor({
    required this.vendorId,
    required this.upiId,
    required this.name,
    required this.type,
    required this.phoneNumber,
    required this.location,  // Include in constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'vendor_id': vendorId,
      'upi_id': upiId,
      'name': name,
      'type': type,
      'phone_number': phoneNumber,
      'location': location,
    };
  }
    
  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      vendorId: map['vendor_id'],
      upiId: map['upi_id'],
      name: map['name'],
      type: map['type'],
      phoneNumber: map['phone_number'],
      location: map['location'],
    );
    }
  }

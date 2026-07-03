class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? photoPath;
  final String relation;
  final String? email;
  final String? address;
  final bool isPrimary; // los primeros 2 marcados reciben el SOS automático

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.photoPath,
    required this.relation,
    this.email,
    this.address,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'photoPath': photoPath,
        'relation': relation,
        'email': email,
        'address': address,
        'isPrimary': isPrimary,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        photoPath: json['photoPath'],
        relation: json['relation'] ?? '',
        email: json['email'],
        address: json['address'],
        isPrimary: json['isPrimary'] ?? false,
      );

  EmergencyContact copyWith({
    String? name,
    String? phone,
    String? photoPath,
    String? relation,
    String? email,
    String? address,
    bool? isPrimary,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      relation: relation ?? this.relation,
      email: email ?? this.email,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

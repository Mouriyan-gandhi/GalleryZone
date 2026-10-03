import '../../models/order.dart';

/// Ported verbatim from `frontend-web/lib/mock-data/customer.ts`'s
/// `mockAddresses` — same ids, so an order placed on either client refers to
/// the same address record.
List<Address> seedAddresses() => const [
      Address(
        id: 'addr-home-pune',
        line1: '12 MG Road',
        line2: 'Flat 4B, Sunrise Apartments',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        isDefault: true,
      ),
      Address(
        id: 'addr-office-mumbai',
        line1: '88 Nariman Point',
        line2: 'Tower 2, 14th Floor',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400021',
        isDefault: false,
      ),
      Address(
        id: 'addr-family-bengaluru',
        line1: '27 Indiranagar 100ft Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560038',
        isDefault: false,
      ),
    ];

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_checkout_repository.dart';
import '../../../data/repositories/checkout_repository.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return MockCheckoutRepository();
});
